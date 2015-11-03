//
//  KWSHeader.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSHeader.h"
#import "KWSBufferReader.h"
#import "KWSUtils.h"

@interface KWSHeader ()
@property (nonatomic, strong) NSMutableDictionary* dict;
@end

@implementation KWSHeader


- (instancetype)init
{
    self = [super init];
    if (self) {
        _dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (nullable instancetype)initWithBytes:(uint8_t*)bytes length:(NSUInteger)length isCRLF:(BOOL)isCRLF
{
    self = [super init];
    if (self) {
        _dict = [[NSMutableDictionary alloc] initWithCapacity:10];
        KWSBufferReader* br = [[KWSBufferReader alloc] initWithBytes:bytes length:length];

        BOOL ok = false;
        while (1) {
            uint8_t* line;
            NSUInteger rLen = [br readBytes:'\n' saveInBytes:&line];
            if (rLen == 0) {
                break;
            }

            NSInteger kvSep = indexByte(line, rLen, ':');
            if (kvSep == -1) {
                free(line);
                break;
            }

            // minus length of '\r\n'
            NSInteger vLen = rLen - 1 - kvSep - 3;
            if (!isCRLF) {
                vLen += 1;
            }

            if (vLen <= 2) {
                free(line);
                break;
            }

            NSString* key = [[NSString alloc] initWithBytes:line length:kvSep encoding:NSUTF8StringEncoding];
            NSMutableArray* values = [_dict objectForKey:key];
            if (values == nil) {
                values = [[NSMutableArray alloc] initWithCapacity:1];
                [_dict setObject:values forKey:key];
            }

            NSString* val = [[NSString alloc] initWithBytes:line + kvSep + 2 length:vLen encoding:NSUTF8StringEncoding];
            [values addObject:val];

            free(line);

            ok = true;
        }


        if (!ok) {
            return nil;
        }
    }
    return self;
}

- (instancetype)setValue:(NSString*)value forKey:(NSString*)key
{
    NSMutableArray* values = [self.dict objectForKey:key];
    if (values == nil) {
        values = [NSMutableArray arrayWithCapacity:1];
    }
    [values addObject:value];
    [self.dict setObject:values forKey:key];
    return self;
}

- (NSMutableArray*)getValuesWithKey:(NSString*)key
{
    return [self.dict objectForKey:key];
}

- (NSString*)getValueWithKey:(NSString*)key
{
    NSMutableArray* values = [self.dict objectForKey:key];
    return [values objectAtIndex:0];
}

- (BOOL)hasKeyAndValueEquals:(NSString*)key value:(NSString*)value
{
    NSMutableArray* values = [self.dict objectForKey:key];
    if (values && [values count]) {
        return [[values objectAtIndex:0] isEqualToString:value];
    }
    return false;
}

- (BOOL)hasKeyAndValContains:(NSString*)key value:(NSString*)value
{
    NSMutableArray* values = [self.dict objectForKey:key];
    if (values && [values count]) {
        return [[values objectAtIndex:0] containsString:value];
    }
    return false;
}

- (NSString*)UTF8String
{
    NSMutableString* str = [[NSMutableString alloc] init];
    for (NSString* key in self.dict) {
        NSMutableArray* values = [self.dict objectForKey:key];
        for (NSString* value in values) {
            [str appendString:[NSString stringWithFormat:@"%@: %@\r\n", key, value]];
        }
    }
    return str;
}

- (NSData*)data
{
    NSMutableString* str = [[NSMutableString alloc] init];
    for (NSString* key in self.dict) {
        NSMutableArray* values = (NSMutableArray*)[self.dict objectForKey:key];
        for (NSString* value in values) {
            [str appendString:[NSString stringWithFormat:@"%@: %@\r\n", key, value]];
        }
    }
    NSData* d = [str dataUsingEncoding:NSUTF8StringEncoding];
    return d;
}

- (void)writeToStream:(NSOutputStream*)outputStream
{
    NSData* d = [self data];
    [outputStream write:[d bytes] maxLength:[d length]];
}

@end
