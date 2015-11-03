//
//  KWSHandshakeRequest.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWSHeader.h"
#import "NSURL+Util.h"
#import "KWSUtils.h"
#import "macros.h"

@interface KWSHandshakeRequest : NSObject
@property (nonatomic, strong) NSString* method;
@property (nonatomic, strong) NSString* requestURI;
@property (nonatomic, strong) NSURL* requestURL;
@property (nonatomic, strong) NSString* protocol;
@property (nonatomic, strong) NSString* protocolVersion;
@property (nonatomic, strong) KWSHeader* header;
@property (nonatomic, strong, readonly) NSString* key;

- (void)applyNewKey;

// apply Upgrade/Connection/Sec-WebSocket-Version/Sec-WebSocket-Key
- (void)applyDefaultHeader;
- (NSData*)data;
- (void)writeToStream:(NSOutputStream*)outputStream;
@end
