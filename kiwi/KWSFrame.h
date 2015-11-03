//
//  KWSFrame.h
//  kiwi
//
//  Created by mconintet on 10/10/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "macros.h"
#import "KWSUtils.h"

typedef NS_ENUM(NSUInteger, KWSOpcode) {
    KWSOpcodeContinue = (UInt8)0x0,
    KWSOpcodeText = (UInt8)0x1,
    KWSOpcodeBinary = (UInt8)0x2,
    KWSOpcodeClose = (UInt8)0x8,
    KWSOpcodePing = (UInt8)0x9,
    KWSOpcodePong = (UInt8)0xA
};

BOOL checkOpcode(UInt8 opcode);

@interface KWSFrame : NSObject
@property (nonatomic, assign) UInt8 FIN;
@property (nonatomic, assign) UInt8 RSV1;
@property (nonatomic, assign) UInt8 RSV2;
@property (nonatomic, assign) UInt8 RSV3;
@property (nonatomic, assign) UInt8 opcode;
@property (nonatomic, assign) UInt8 mask;
@property (nonatomic, assign) UInt64 payloadLen;
@property (nonatomic, assign) UInt32 maskingKey;
@property (nonatomic, strong) NSData* payloadData;

// return value will be nil if some errors occur when parsing bytes
- (instancetype)initFromStream:(NSInputStream*)inputStream maxPayloadLen:(UInt64)maxPayloadLen;

// it's caller's responsibility to release returned NSData
- (NSData*)newDataWithMask:(NSData*)maskingKey;

// it's caller's responsibility to release returned NSData, this mehtod will apply a random masking key automatically
- (NSData*)newData;

- (BOOL)writeToStream:(NSOutputStream*)outputStream;
@end
