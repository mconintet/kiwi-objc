//
//  KWSHeader.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KWSHeader : NSObject

// return value will be nil if bytes is deformed to be a valid header
- (instancetype)initWithBytes:(uint8_t*)bytes length:(NSUInteger)length isCRLF:(BOOL)isCRLF;

- (instancetype)setValue:(NSString*)value forKey:(NSString*)key;

- (NSMutableArray*)getValuesWithKey:(NSString*)key;
- (NSString*)getValueWithKey:(NSString*)key;

- (BOOL)hasKeyAndValueEquals:(NSString*)key value:(NSString*)value;
- (BOOL)hasKeyAndValContains:(NSString*)key value:(NSString*)value;

- (NSString*)UTF8String;
- (NSData*)data;
- (void)writeToStream:(NSOutputStream*)outputStream;
@end
