//
//  NSURL+Util.m
//  kiwi
//
//  Created by mconintet on 10/8/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "NSURL+Util.h"

@implementation NSURL (Util)
- (NSString*)resourceIdentifier
{
    NSString* path = self.path;
    if (!path || [path isEqualToString:@""]) {
        path = @"/";
    }

    if (!self.query || [self.query isEqualToString:@""]) {
        return path;
    }
    return [NSString stringWithFormat:@"%@?%@", path, self.query];
}

- (NSString*)hostPort
{
    if (self.port) {
        return [NSString stringWithFormat:@"%@:%@", self.host, self.port];
    }
    return self.host;
}

- (int)portAsInt
{
    NSNumber* port = self.port;
    if (port == nil) {
        return 80;
    }
    return [port intValue];
}
@end
