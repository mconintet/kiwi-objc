//
//  KWSBufferReader.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KWSBufferReader : NSObject
- (instancetype)initWithBytes:(uint8_t*)bytes
                       length:(NSUInteger)length;

- (NSUInteger)readBytes:(uint8_t)delimiter
            saveInBytes:(uint8_t**)bytes;
@end
