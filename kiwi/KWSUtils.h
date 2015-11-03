//
//  KWSUtils.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "macros.h"

NSInteger indexByte(uint8_t* s, NSUInteger sl, uint8_t c);

NSInteger bytesCompare(uint8_t* bytes1, uint8_t* bytes2, NSInteger len);

NSData* sha1(NSString* input);

#ifndef readBytesAsMatchBufSize
#define readBytesAsMatchBufSize 512
#endif
// return value will be nil if some errors occur such as bytes within input stream
// is less than the size which been required
// NOTE:
//   1. it's caller's responsibility to release the return value after using
//   2. caller would to check if the size of returned NSData is equal to it's expectation
NSData* readBytesAsMatch(NSInputStream* inputStream, UInt64 size);

// it's caller's responsibility to release the return value after using
NSData* makeMaskingkey();

void maskData(NSData* data, NSData* maskingKey);
