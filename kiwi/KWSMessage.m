//
//  KWSMessage.m
//  kiwi
//
//  Created by mconintet on 10/10/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSMessage.h"

@interface KWSMessage ()
@property (nonatomic, assign) NSUInteger dataLength;
@end

@implementation KWSMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)appendFrame:(KWSFrame*)frame
{
    DLOG(@"message append frame data length: %llu real: %lu", frame.payloadLen, (unsigned long)[frame.payloadData length]);
    DLOG_NSData(frame.payloadData);

    [self.data appendData:frame.payloadData];
    if (frame.FIN == 1) {
        _isFilled = true;
    }
}

- (NSString*)newString
{
    NSString* str = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    return str;
}

@end
