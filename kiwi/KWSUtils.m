//
//  KWSUtils.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSUtils.h"

NSInteger indexByte(uint8_t* s, NSUInteger sl, uint8_t c)
{
    int i = 0;
    int found = -1;
    while (i < sl) {
        if (s[i] == c) {
            found = i;
            break;
        }
        i++;
    }
    return found;
}

NSInteger bytesCompare(uint8_t* bytes1, uint8_t* bytes2, NSInteger len)
{
    for (NSInteger i = 0; i < len; i++) {
        if (bytes1[i] != bytes2[i]) {
            return false;
        }
    }
    return true;
}

NSData* sha1(NSString* input)
{
    NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (uint)data.length, digest);

    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

NSData* readBytesAsMatch(NSInputStream* inputStream, UInt64 size)
{
    NSInteger bufSize = (NSInteger)MIN(readBytesAsMatchBufSize, size);
    uint8_t buf[bufSize];
    NSMutableData* data = [[NSMutableData alloc] initWithCapacity:(NSInteger)size];

    NSInteger rLen = 0;
    while (1) {
        if ([data length] == size) {
            break;
        }

        rLen = [inputStream read:buf maxLength:bufSize];
        if (rLen <= 0) {
#ifdef DEBUG
            if (rLen < 0) {
                DLOG(@"readBytesAsMatch: errors occur when reading: %ld", (long)rLen);
            }
#endif
            break;
        }

        [data appendBytes:buf length:rLen];
    }

    return data;
}

// it's caller's responsibility to release returned NSData
NSData* makeMaskingkey()
{
    UInt32 r;
    arc4random_buf(&r, sizeof(r));
    NSMutableData* data = [[NSMutableData alloc] initWithCapacity:4];
    uint8_t buf[4] = {
        (uint8_t)(r >> 24),
        (uint8_t)(r >> 16),
        (uint8_t)(r >> 8),
        (uint8_t)r,
    };
    [data appendBytes:buf length:4];
    return data;
}

void maskData(NSMutableData* data, NSData* maskingKey)
{
    uint8_t* mkb = (uint8_t*)[maskingKey bytes];
    uint8_t* db = (uint8_t*)[data bytes];

    for (int i = 0, j = 0; i < [data length]; i++) {
        j = i % 4;
        db[i] = db[i] ^ mkb[j];
    }
}
