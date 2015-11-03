//
//  KWSHandshakeRequest.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSHandshakeRequest.h"

@implementation KWSHandshakeRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _method = @"GET";
        _protocol = @"HTTP";
        _protocolVersion = @"1.1";
        _header = [[KWSHeader alloc] init];
    }
    return self;
}

- (NSData*)data
{
    NSMutableString* str = [[NSMutableString alloc] initWithCapacity:512];
    [str appendFormat:@"%@ %@ %@/%@\r\n",
         self.method,
         [self.requestURL resourceIdentifier],
         self.protocol,
         self.protocolVersion];

    [str appendFormat:@"Host: %@\r\n", [self.requestURL hostPort]];
    [str appendString:[self.header UTF8String]];
    [str appendString:@"\r\n"];

    NSData* d = [str dataUsingEncoding:NSUTF8StringEncoding];
    return d;
}

- (void)writeToStream:(NSOutputStream*)outputStream
{
    NSData* d = [self data];
    DLOG(@"request:\n%@", [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]);
    [outputStream write:[d bytes] maxLength:[d length]];
}

- (void)applyNewKey
{
    UInt16 r;
    arc4random_buf(&r, sizeof(UInt16));
    NSData* data = [[NSData alloc] initWithBytes:(uint8_t*)&r length:2];
    _key = [data base64EncodedStringWithOptions:0];
}

- (void)applyDefaultHeader
{
    KWSHeader* h = _header;
    [h setValue:@"websocket" forKey:@"Upgrade"];
    [h setValue:@"Upgrade" forKey:@"Connection"];
    [h setValue:@"13" forKey:@"Sec-WebSocket-Version"];

    [self applyNewKey];
    [h setValue:_key forKey:@"Sec-WebSocket-Key"];
}
@end
