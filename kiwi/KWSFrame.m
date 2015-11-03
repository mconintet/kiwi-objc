//
//  KWSFrame.m
//  kiwi
//
//  Created by mconintet on 10/10/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSFrame.h"

BOOL checkOpcode(UInt8 opcode)
{
    return opcode == KWSOpcodeContinue
        || opcode == KWSOpcodeText
        || opcode == KWSOpcodeBinary
        || opcode == KWSOpcodeClose
        || opcode == KWSOpcodePing
        || opcode == KWSOpcodePing
        || opcode == KWSOpcodePong;
}

@implementation KWSFrame

- (instancetype)initFromStream:(NSInputStream*)inputStream maxPayloadLen:(UInt64)maxPayloadLen
{
    self = [super init];
    if (self) {
        uint8_t byt2[2];
        NSInteger rLen = [inputStream read:byt2 maxLength:2];
        if (rLen != 2) {
            DLOG(@"ErrDeformedFirstTwoBytes");
            return nil;
        }

        _FIN = byt2[0] >> 7;
        _RSV1 = (byt2[0] << 1) >> 7;
        _RSV2 = (byt2[0] << 2) >> 7;
        _RSV3 = (byt2[0] << 3) >> 7;
        _opcode = byt2[0] & 0xF;

        DLOG(@"FIN %d opcode %d", _FIN, _opcode);
        if (!checkOpcode(_opcode)) {
            DLOG(@"ErrDeformedOpcode");
            return nil;
        }

        _mask = byt2[1] >> 7;
        UInt8 pLen = byt2[1] & 0x7F;

        DLOG(@"pLen: %d", pLen);
        if (pLen <= 125) {
            _payloadLen = (UInt64)pLen;
        }
        else if (pLen == 126) {
            UInt16 p16;
            rLen = [inputStream read:byt2 maxLength:2];
            if (rLen != 2) {
                DLOG(@"ErrDeformedExtendedPayloadLength");
                return nil;
            }

            p16 = ((UInt16)byt2[0] << 8) | (UInt16)byt2[1];
            _payloadLen = (UInt64)p16;
        }
        else if (pLen == 127) {
            UInt64 p64;
            uint8_t byt8[8];
            rLen = [inputStream read:byt8 maxLength:8];
            if (rLen != 8) {
                DLOG(@"ErrDeformedExtendedPayloadLength");
                return nil;
            }

            p64 = (UInt64)byt8[0] << 56
                | (UInt64)byt8[1] << 48
                | (UInt64)byt8[2] << 40
                | (UInt64)byt8[3] << 32
                | (UInt64)byt8[4] << 24
                | (UInt64)byt8[5] << 16
                | (UInt64)byt8[6] << 8
                | (UInt64)byt8[7];

            _payloadLen = p64;
        }
        else {
            DLOG(@"deformed payload length");
            return nil;
        }

        DLOG(@"payloadLen: %llu", _payloadLen);
        if (_payloadLen > maxPayloadLen) {
            DLOG(@"ErrFrameTooLarge");
            return nil;
        }

        if (_mask == 1) {
            uint8_t mkb[4];
            rLen = [inputStream read:mkb maxLength:4];
            if (rLen != 4) {
                DLOG(@"ErrDeformedMaskingKey");
                return nil;
            }

            _maskingKey = (UInt32)mkb[0] << 24
                | (UInt32)mkb[1] << 16
                | (UInt32)mkb[2] << 8
                | (UInt32)mkb[3];
        }

        if (pLen > 0) {
            NSData* data = readBytesAsMatch(inputStream, _payloadLen);
            if ([data length] != _payloadLen) {
                DLOG(@"ErrDeformedPayloadData");
                return nil;
            }

            _payloadData = data;
        }
    }
    return self;
}

- (NSData*)newDataWithMask:(NSData*)maskingKey
{
    NSMutableData* data = [[NSMutableData alloc] init];
    uint8_t fb = self.FIN << 7
        | self.RSV1 << 6
        | self.RSV2 << 5
        | self.RSV3 << 4
        | self.opcode;

    DLOG(@"fb: %x", fb);

    [data appendBytes:&fb length:1];

    UInt8 sb = maskingKey ? 1 << 7 : 0;

    NSUInteger pLength = [self.payloadData length];
    DLOG(@"pLength: %lu", (unsigned long)pLength);

    if (pLength <= 125) {
        sb |= pLength;
        [data appendBytes:&sb length:1];
    }
    else if (pLength <= UINT16_MAX) {
        sb |= 126;
        [data appendBytes:&sb length:1];
        uint8_t ep[2] = {
            (uint8_t)((UInt16)pLength >> 8),
            (uint8_t)pLength
        };
        [data appendBytes:ep length:2];
    }
    else {
        UInt64 p64 = (UInt64)pLength;
        sb |= 127;
        [data appendBytes:&sb length:1];
        uint8_t ep[8] = {
            (uint8_t)(p64 >> 56),
            (uint8_t)(p64 >> 48),
            (uint8_t)(p64 >> 40),
            (uint8_t)(p64 >> 32),
            (uint8_t)(p64 >> 24),
            (uint8_t)(p64 >> 16),
            (uint8_t)(p64 >> 8),
            (uint8_t)p64
        };
        [data appendBytes:ep length:8];
    }

    if (maskingKey) {
        [data appendData:maskingKey];
        maskData(self.payloadData, maskingKey);
    }

    [data appendData:self.payloadData];
    return data;
}

- (NSData*)newData
{
    NSData* mk = makeMaskingkey();
    NSData* data = [self newDataWithMask:mk];
    return data;
}

- (BOOL)writeToStream:(NSOutputStream*)outputStream
{
    NSData* data = [self newData];
    NSInteger wLen = [outputStream write:[data bytes] maxLength:[data length]];

    BOOL ok = wLen == [data length];
    DLOG(@"wrote data:");
    DLOG_NSData(data);
    DLOG(@"isOK %d length:%lu wrote length: %ld", ok, (unsigned long)[data length], (long)wLen);

    return ok;
}

@end
