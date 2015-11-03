//
//  KWSBufferReader.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSBufferReader.h"

@interface KWSBufferReader ()
@property (nonatomic, assign) uint8_t* bytes;
@property (nonatomic, assign) NSUInteger length;
@property (nonatomic, assign) NSUInteger readIndex;
@end

@implementation KWSBufferReader

- (instancetype)initWithBytes:(uint8_t*)bytes length:(NSUInteger)length
{
    self = [super init];
    if (self) {
        _bytes = bytes;
        _length = length;
    }
    return self;
}

- (NSUInteger)readBytes:(uint8_t)delimiter
            saveInBytes:(uint8_t**)bytes
{
    NSUInteger i = self.readIndex;
    NSUInteger len = 0;
    while (i < self.length) {
        if (self.bytes[i] == delimiter) {
            len = i - self.readIndex + 1;
            break;
        }
        i++;
    }

    if (len) {
        *bytes = calloc(sizeof(uint8_t), len);
        memcpy(*bytes, self.bytes + self.readIndex, len);
        self.readIndex += len;
    }
    return len;
}
@end
