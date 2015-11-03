//
//  macros.h
//  kiwi
//
//  Created by mconintet on 10/8/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLOG(...)
#endif

#define int2NSNumber(i) [NSNumber numberWithInt:i]

#ifdef DEBUG
#define DLOG_NSData(d)                                                   \
    do {                                                                 \
        NSMutableString* log = [NSMutableString stringWithString:@"[ "]; \
        NSUInteger len = [d length];                                     \
        uint8_t* byts = (uint8_t*)[d bytes];                             \
        for (NSUInteger i = 0; i < len; i++) {                           \
            [log appendFormat:@"%x ", byts[i]];                          \
        }                                                                \
        [log appendString:@"]\n"];                                       \
        NSLog(@"%@", log);                                               \
    } while (0);
#else
#define DLOG_NSData(...)
#endif
