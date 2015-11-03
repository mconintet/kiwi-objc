//
//  KWSHandshakeResponse.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSHandshakeResponse.h"

const static NSString* keySuffixGUID = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

static uint8_t emptyLine1[] = { '\n', '\n' };
static uint8_t emptyLine2[] = { '\r', '\n', '\r', '\n' };

BOOL checkLastEmptyLine(uint8_t* bytes, NSInteger bLen, BOOL* isCRLF)
{
    if (bLen > 2 && bytesCompare(bytes + bLen - 2, emptyLine1, 2)) {
        *isCRLF = false;
        return true;
    }
    else if (bLen > 4 && bytesCompare(bytes + bLen - 4, emptyLine2, 4)) {
        *isCRLF = true;
        return true;
    }
    return false;
}

@implementation KWSHandshakeResponse


- (instancetype)initFromStream:(NSInputStream*)inputStream
{
    self = [super init];
    if (self) {
        uint8_t buf[KWSHandshakeResponseMaxBytes];
        NSInteger bLen = [inputStream read:buf maxLength:KWSHandshakeResponseMaxBytes];

        DLOG(@"response:\n%@", [[NSString alloc] initWithBytes:buf length:bLen encoding:NSUTF8StringEncoding]);

        // minimum content muse be:
        // h 2 t\n\n
        if (bLen < 5) {
            DLOG(@"response too small: %ld buf size:%d", (long)bLen, KWSHandshakeResponseMaxBytes);
            return nil;
        }

        BOOL isCRLF;
        if (!checkLastEmptyLine(buf, bLen, &isCRLF)) {
            DLOG(@"missing last empty line");
            return nil;
        }

        KWSBufferReader* br = [[KWSBufferReader alloc] initWithBytes:buf length:bLen];

        // parse status line
        // example: HTTP/1.1 200 OK
        uint8_t* line;
        NSInteger slLen = [br readBytes:'\n' saveInBytes:&line];

        NSInteger s1 = indexByte(line, slLen, ' ');
        NSInteger s2 = indexByte(line + s1 + 1, slLen - 1 - s1, ' ');
        if (s1 < 0 || s2 < 0) {
            DLOG(@"deformed status line");
            return nil;
        }
        s2 += s1 + 1;

        NSString* code = [[NSString alloc] initWithBytes:line + s1 + 1 length:s2 - s1 - 1 encoding:NSUTF8StringEncoding];
        _statusCode = [code integerValue];
        if (_statusCode == 0) {
            DLOG(@"deformed status code: %@", code);
            return nil;
        }

        // remove last empty line
        NSInteger hLen = bLen - slLen - 2;
        if (!isCRLF) {
            hLen += 1;
        }
        KWSHeader* header = [[KWSHeader alloc] initWithBytes:buf + slLen length:hLen isCRLF:isCRLF];
        if (header == nil) {
            DLOG(@"deformed headers");
            return nil;
        }
        _header = header;

        free(line);
    }
    return self;
}

- (NSString*)makeAcceptKey:(NSString*)requestKey
{
    NSString* key = [NSString stringWithFormat:@"%@%@", requestKey, keySuffixGUID];
    NSData* data = sha1(key);
    return [data base64EncodedStringWithOptions:0];
}

- (BOOL)verifyAcceptKey:(NSString*)acceptKey requestKey:(NSString*)requestKey
{
    NSString* ak = [self makeAcceptKey:requestKey];
    if (![ak isEqualToString:acceptKey]) {
        DLOG(@"verifyAcceptKey requestKey:%@ wish:%@ got:%@", requestKey, ak, acceptKey);
        return false;
    }
    return true;
}

@end
