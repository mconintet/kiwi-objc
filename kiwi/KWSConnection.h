//
//  KWSConnection.h
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWSHandshakeRequest.h"
#import "KWSHandshakeResponse.h"
#import "KWSFrame.h"
#import "KWSMessage.h"

#ifndef KWSFrameMaxPayloadSize
#define KWSFrameMaxPayloadSize 1 << 20
#endif

typedef NS_ENUM(NSUInteger, KWSConnectionStatus) {
    KWSConnectionStatusPending = 0,
    KWSConnectionStatusConnecting = 1,
    KWSConnectionStatusOpen = 2,
    KWSConnectionStatusClosing = 3,
    KWSConnectionStatusClosed = 4
};

typedef NS_ENUM(UInt16, KWSCloseCode) {
    KWSCloseCodeNormalClosure = (UInt16)1000,
    KWSCloseCodeGoingAway = (UInt16)1001,
    KWSCloseCodeProtocolError = (UInt16)1002,
    KWSCloseCodeUnsupportedData = (UInt16)1003,
    KWSCloseCodeNoStatusRcvd = (UInt16)1005,
    KWSCloseCodeAbnormalClosure = (UInt16)1006,
    KWSCloseCodeInvalidFramePayloadData = (UInt16)1007,
    KWSCloseCodePolicyViolation = (UInt16)1008,
    KWSCloseCodeMessageTooBig = (UInt16)1009,
    KWSCloseCodeMandatoryExt = (UInt16)1010,
    KWSCloseCodeInternalServerError = (UInt16)1011,
    KWSCloseCodeTLSHandshake = (UInt16)1015
};

@class KWSConnection;

typedef BOOL (^KWSConnectionOnHandshakeRequestHandler)(KWSConnection*);
typedef BOOL (^KWSConnectionOnHandshakeResponseHandler)(KWSConnection*);
typedef BOOL (^KWSConnectionOnOpenHandler)(KWSConnection*);

// it's handler's responsibility to release KWSMessage
typedef BOOL (^KWSConnectionOnMessageHandler)(KWSMessage*, KWSConnection*);
typedef BOOL (^KWSConnectionOnFrameHandler)(KWSFrame*, KWSConnection*);

typedef void (^KWSConnectionOnClosedHandler)(void);
typedef void (^KWSConnectionOnErrorHandler)(NSError*);
typedef void (^KWSConnectionTimeoutHandler)(void);

@interface KWSRawConnection : NSObject
@property (strong, nonatomic) NSInputStream* inputStream;
@property (strong, nonatomic) NSOutputStream* outputStream;

- (void)scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode;
- (void)close;
@end

@protocol KWSMessageReceiverDelegate <NSObject>
- (BOOL)processFrame:(KWSFrame*)frame withConn:(KWSConnection*)conn;
- (BOOL)hasNewMessage;
- (KWSMessage*)newMessage;
@end

@interface KWSDefaultMessageReceiver : NSObject <KWSMessageReceiverDelegate>
@end

@protocol KWSMessageSenderDelegate <NSObject>
- (instancetype)initWithKWSConnection:(KWSConnection*)connection;

- (BOOL)sendControlFrameWithOpcode:(NSUInteger)opcode data:(NSData*)data;
- (BOOL)sendCloseFrameWithCode:(NSInteger)code reason:(NSString*)reason;
- (BOOL)sendPingFrame;
- (BOOL)sendPongFrame;

- (BOOL)sendWithString:(NSString*)string;
- (BOOL)sendMessage:(KWSMessage*)message;
- (BOOL)sendWithData:(NSData*)data opcode:(NSUInteger)opcode frameSize:(NSUInteger)frameSize;
- (BOOL)sendWithStream:(NSInputStream*)inputStream opcode:(NSUInteger)opcode frameSize:(NSUInteger)frameSize;
@end

@interface KWSDefaultMessageSender : NSObject <KWSMessageSenderDelegate>
@end

@interface KWSConnection : NSObject <NSStreamDelegate>

@property (nonatomic, assign) NSUInteger status;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) KWSRawConnection* rawConnection;

@property (nonatomic, strong) id<KWSMessageReceiverDelegate> messageReceiver;
@property (nonatomic, strong) id<KWSMessageSenderDelegate> messageSender;

@property (nonatomic, strong) KWSHandshakeRequest* handshakeRequest;
@property (nonatomic, strong) KWSHandshakeResponse* handshakeReponse;

@property (nonatomic, strong) KWSConnectionOnHandshakeRequestHandler onHandshakeRequestHandler;
@property (nonatomic, strong) KWSConnectionOnHandshakeResponseHandler onHandshakeResponseHandler;
@property (nonatomic, strong) KWSConnectionOnOpenHandler onOpenHandler;

// it's handler's responsibility to release KWSMessage
@property (nonatomic, strong) KWSConnectionOnMessageHandler onMessageHandler;
@property (nonatomic, strong) KWSConnectionOnClosedHandler onClosedHandler;
@property (nonatomic, strong) KWSConnectionOnErrorHandler onErrorHandler;

@property (nonatomic, assign) NSInteger frameMaxPayloadSize;
@property (nonatomic, strong) KWSConnectionOnFrameHandler onFrameHandler;
@property (nonatomic, strong) KWSConnectionTimeoutHandler onTimeoutHandler;

+ (NSString*)closeTextWithCode:(UInt16)code;

- (instancetype)initWithURL:(NSURL*)url;

- (void)connectWithTimeout:(NSTimeInterval)timeout;
- (void)scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode;
- (void)close;
- (void)closeWithCode:(UInt16)code reason:(NSString*)reason;
@end
