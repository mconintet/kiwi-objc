//
//  KWSHandshakeResponse.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWSHeader.h"
#import "KWSBufferReader.h"
#import "KWSUtils.h"
#import "macros.h"

#ifndef KWSHandshakeResponseMaxBytes
#define KWSHandshakeResponseMaxBytes 4096
#endif

@interface KWSHandshakeResponse : NSObject
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) KWSHeader* header;

// return value will be nil if some errors occur when parsing bytes
- (instancetype)initFromStream:(NSInputStream*)inputStream;

- (BOOL)verifyAcceptKey:(NSString*)acceptKey requestKey:(NSString*)requestKey;
@end
