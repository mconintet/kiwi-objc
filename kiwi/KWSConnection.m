//
//  KWSConnection.m
//  kiwi
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "KWSConnection.h"

@interface KWSRawConnection ()
@property (nonatomic, strong) NSRunLoop* aRunLoop;
@property (nonatomic, strong) NSString* mode;
@end

@implementation KWSRawConnection

- (void)scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode
{
    self.aRunLoop = aRunLoop;
    self.mode = mode;

    [self.inputStream open];
    [self.outputStream open];

    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSDefaultRunLoopMode];
}

- (void)close
{
    [self.inputStream removeFromRunLoop:self.aRunLoop forMode:self.mode];
    [self.outputStream removeFromRunLoop:self.aRunLoop forMode:self.mode];

    [self.inputStream close];
    [self.outputStream close];
}

@end

@interface KWSDefaultMessageReceiver ()
@property (nonatomic, strong) KWSMessage* tmpMessage;
@end

@implementation KWSDefaultMessageReceiver

- (void)prepareTmpMessage
{
    if (_tmpMessage == nil) {
        _tmpMessage = [[KWSMessage alloc] init];
    }
}

- (BOOL)processFrame:(KWSFrame*)frame withConn:(KWSConnection*)conn
{
    [self prepareTmpMessage];
    [_tmpMessage appendFrame:frame];
    return true;
}

- (BOOL)hasNewMessage
{
    return _tmpMessage && _tmpMessage.isFilled;
}
- (KWSMessage*)newMessage
{
    KWSMessage* message = _tmpMessage;
    _tmpMessage = nil;
    return message;
}
@end

@interface KWSDefaultMessageSender ()
@property (nonatomic, weak) KWSConnection* connection;
@property (nonatomic, strong) dispatch_semaphore_t sendingSemaphore;
@end

@implementation KWSDefaultMessageSender

- (instancetype)initWithKWSConnection:(KWSConnection*)connection;
{
    self = [super init];
    if (self) {
        _connection = connection;
        _sendingSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (BOOL)sendControlFrameWithOpcode:(NSUInteger)opcode data:(NSData*)data
{
    BOOL ok;
    @autoreleasepool
    {
        KWSFrame* frame = [[KWSFrame alloc] init];
        frame.opcode = opcode;
        frame.payloadData = data;
        ok = [frame writeToStream:self.connection.rawConnection.outputStream];
    }
    return ok;
}

- (BOOL)sendCloseFrameWithCode:(NSInteger)code reason:(NSString*)reason
{
    code = code ? code : KWSCloseCodeNormalClosure;

    NSMutableData* data = [[NSMutableData alloc] init];
    uint8_t cb[2] = {
        (UInt8)(code >> 8),
        (UInt8)code
    };
    [data appendBytes:cb length:2];

    if (!reason || [reason isEqualToString:@""]) {
        reason = [KWSConnection closeTextWithCode:code];
    }
    [data appendData:[reason dataUsingEncoding:NSUTF8StringEncoding]];

    KWSFrame* frame = [[KWSFrame alloc] init];
    frame.FIN = 1;
    frame.opcode = KWSOpcodeClose;
    frame.payloadData = data;

    BOOL ok = [frame writeToStream:self.connection.rawConnection.outputStream];

    return ok;
}

- (BOOL)sendPingFrame
{
    KWSFrame* frame = [[KWSFrame alloc] init];
    frame.FIN = 1;
    frame.opcode = KWSOpcodePing;
    BOOL ok = [frame writeToStream:self.connection.rawConnection.outputStream];
    return ok;
}

- (BOOL)sendPongFrame
{
    KWSFrame* frame = [[KWSFrame alloc] init];
    frame.FIN = 1;
    frame.opcode = KWSOpcodePong;
    BOOL ok = [frame writeToStream:self.connection.rawConnection.outputStream];
    return ok;
}

- (BOOL)sendMessage:(KWSMessage*)message
{
    BOOL ok;
    @autoreleasepool
    {
        KWSFrame* frame = [[KWSFrame alloc] init];
        frame.FIN = 1;
        frame.opcode = message.opcode;
        frame.payloadData = message.data;
        ok = [frame writeToStream:self.connection.rawConnection.outputStream];
    }
    return ok;
}

- (BOOL)sendWithString:(NSString*)string
{
    BOOL ok;
    @autoreleasepool
    {
        KWSFrame* frame = [[KWSFrame alloc] init];
        frame.FIN = 1;
        frame.opcode = KWSOpcodeText;
        frame.payloadData = [string dataUsingEncoding:NSUTF8StringEncoding];
        ok = [frame writeToStream:self.connection.rawConnection.outputStream];
    }
    return ok;
}

- (BOOL)sendWithData:(NSData*)data
              opcode:(NSUInteger)opcode
           frameSize:(NSUInteger)frameSize
{
    dispatch_semaphore_wait(_sendingSemaphore, DISPATCH_TIME_FOREVER);
    frameSize = frameSize ? frameSize : KWSFrameMaxPayloadSize;

    NSUInteger remainSize = [data length];
    NSUInteger i = 0;

    while (remainSize) {
        frameSize = MIN(remainSize, frameSize);
        uint8_t buf[frameSize];
        [data getBytes:buf length:frameSize];
        remainSize -= frameSize;

        KWSFrame* frame = [[KWSFrame alloc] init];

        if (i == 0)
            frame.opcode = opcode;
        if (remainSize == 0)
            frame.FIN = 1;

        NSData* data = [[NSData alloc] initWithBytes:buf length:frameSize];
        frame.payloadData = data;

        BOOL ok = [frame writeToStream:self.connection.rawConnection.outputStream];

        if (!ok)
            return false;

        i++;
    }

    dispatch_semaphore_signal(_sendingSemaphore);
    return true;
}

- (BOOL)sendWithStream:(NSInputStream*)inputStream
                opcode:(NSUInteger)opcode
             frameSize:(NSUInteger)frameSize
{
    dispatch_semaphore_wait(_sendingSemaphore, DISPATCH_TIME_FOREVER);
    frameSize = frameSize ? frameSize : KWSFrameMaxPayloadSize;

    NSUInteger i = 0;
    KWSFrame* frame = nil;

    while (1) {
        uint8_t buf[frameSize];
        NSInteger rLen = [inputStream read:buf maxLength:frameSize];

        if (frame != nil) {
            if (rLen == 0) {
                frame.FIN = 1;
            }

            BOOL ok = [frame writeToStream:self.connection.rawConnection.outputStream];

            if (!ok) {
                return false;
            }
            if (rLen == 0) {
                break;
            }
        }

        frame = [[KWSFrame alloc] init];
        NSData* data = [[NSData alloc] initWithBytes:buf length:rLen];
        frame.payloadData = data;

        if (i == 0)
            frame.opcode = opcode;

        i++;
    }

    dispatch_semaphore_signal(_sendingSemaphore);
    return true;
}

@end

@interface KWSConnection ()
@property (nonatomic, strong) NSTimer* timeoutTimer;
@end

@implementation KWSConnection

static NSDictionary* KWSCloseCodeTextDict = nil;

+ (NSString*)closeTextWithCode:(UInt16)code
{
    if (KWSCloseCodeTextDict == nil) {
        KWSCloseCodeTextDict = @{
            int2NSNumber(KWSCloseCodeNormalClosure) : @"Normal Closure",
            int2NSNumber(KWSCloseCodeGoingAway) : @"Going Away",
            int2NSNumber(KWSCloseCodeProtocolError) : @"Protocol error",
            int2NSNumber(KWSCloseCodeUnsupportedData) : @"Unsupported Data",
            int2NSNumber(KWSCloseCodeNoStatusRcvd) : @"No Status Rcvd",
            int2NSNumber(KWSCloseCodeAbnormalClosure) : @"Abnormal Closure",
            int2NSNumber(KWSCloseCodeInvalidFramePayloadData) : @"Invalid frame payload data",
            int2NSNumber(KWSCloseCodePolicyViolation) : @"Policy Violation",
            int2NSNumber(KWSCloseCodeMessageTooBig) : @"Message Too Big",
            int2NSNumber(KWSCloseCodeMandatoryExt) : @"Mandatory Ext",
            int2NSNumber(KWSCloseCodeInternalServerError) : @"Internal Server Error",
            int2NSNumber(KWSCloseCodeTLSHandshake) : @"TLS handshake"
        };
    }

    NSNumber* num = [NSNumber numberWithInt:code];
    return [KWSCloseCodeTextDict objectForKey:num];
}

- (KWSConnectionOnHandshakeRequestHandler)KWSDefaultOnHandshakeRequestHandler
{
    return ^BOOL(KWSConnection* conn) {
        DLOG(@"KWSDefaultOnHandshakeRequestHandler");
        [conn.handshakeRequest writeToStream:conn.rawConnection.outputStream];
        return true;
    };
}

- (KWSConnectionOnHandshakeResponseHandler)
    KWSDefaultOnHandshakeResponseHandler
{
    return ^BOOL(KWSConnection* conn) {
        NSString* acceptKey =
            [conn.handshakeReponse.header getValueWithKey:@"Sec-WebSocket-Accept"];
        if (!acceptKey || [acceptKey isEqualToString:@""]) {
            DLOG(@"missing accept key, received: %@", conn.handshakeReponse.header);
            return false;
        }
        return [conn.handshakeReponse verifyAcceptKey:acceptKey
                                           requestKey:conn.handshakeRequest.key];
    };
}

- (KWSConnectionOnErrorHandler)KWSDefaultOnErrorHandler
{
    return ^(NSError* err) {
        DLOG(@"%@", err);
    };
}

- (KWSConnectionOnFrameHandler)KWSDefaultOnFrameHandler
{
    return ^BOOL(KWSFrame* frame, KWSConnection* conn) {
        DLOG(@"KWSConnectionOnFrameHandler");
        [conn.messageReceiver processFrame:frame withConn:conn];
        if (conn.onMessageHandler && [conn.messageReceiver hasNewMessage]) {
            KWSMessage* message = [conn.messageReceiver newMessage];
            conn.onMessageHandler(message, conn);
        }
        return true;
    };
}

- (void)applyDefaultSettings
{
    _onHandshakeRequestHandler = [self KWSDefaultOnHandshakeRequestHandler];
    _onHandshakeResponseHandler = [self KWSDefaultOnHandshakeResponseHandler];
    _onErrorHandler = [self KWSDefaultOnErrorHandler];

    _frameMaxPayloadSize = _frameMaxPayloadSize ? _frameMaxPayloadSize : KWSFrameMaxPayloadSize;
    _onFrameHandler = [self KWSDefaultOnFrameHandler];

    _messageReceiver = [[KWSDefaultMessageReceiver alloc] init];
    _messageSender = [[KWSDefaultMessageSender alloc] initWithKWSConnection:self];
}

- (instancetype)initWithURL:(NSURL*)url
{
    self = [super init];
    if (self) {
        [self applyDefaultSettings];

        _handshakeRequest = [[KWSHandshakeRequest alloc] init];
        _handshakeRequest.requestURL = url;
        _handshakeRequest.requestURI = [url resourceIdentifier];
        [_handshakeRequest applyDefaultHeader];
        [_handshakeRequest.header setValue:@"Host" forKey:url.hostPort];
    }
    return self;
}

- (void)connectWithTimeout:(NSTimeInterval)timeout
{
    _timeout = timeout;

    NSString* host = [self.handshakeRequest.requestURL host];
    int port = [self.handshakeRequest.requestURL portAsInt];
    DLOG(@"connect to %@:%d", host, port);

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port,
        &readStream, &writeStream);

    KWSRawConnection* rawConn = [[KWSRawConnection alloc] init];
    rawConn.inputStream = (__bridge NSInputStream*)readStream;
    rawConn.outputStream = (__bridge NSOutputStream*)writeStream;
    _rawConnection = rawConn;

    [rawConn.inputStream setDelegate:self];
    [rawConn.outputStream setDelegate:self];

    _status = KWSConnectionStatusPending;
}

- (void)scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode
{
    if (self.status == KWSConnectionStatusPending) {
        [self.rawConnection scheduleInRunLoop:aRunLoop forMode:mode];

        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:_timeout
                                                             target:self
                                                           selector:@selector(handleConnectionTimeout)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)handleConnectionTimeout
{
    DLOG(@"timeout status %lu", (unsigned long)self.status);
    if (self.status != KWSConnectionStatusOpen) {
        if (self.onTimeoutHandler) {
            self.onTimeoutHandler();
        }
        [self close];
    }
}

- (void)fireOnError:(NSString*)errStr
{
    NSDictionary* dict = @{ @"message" : errStr };
    NSError* error =
        [NSError errorWithDomain:@"com.mconintet.kiwi"
                            code:-1000
                        userInfo:dict];
    self.onErrorHandler(error);
    if (self.status == KWSConnectionStatusOpen) {
        [self close];
    }
    else {
        [self.rawConnection close];
    }
}

- (void)fireOnClosed
{
    if (self.onClosedHandler) {
        self.onClosedHandler();
    }
}

- (void)close
{
    switch (self.status) {
    case KWSConnectionStatusPending:
    case KWSConnectionStatusConnecting:
        [self.rawConnection close];
        self.status = KWSConnectionStatusClosed;
        [self fireOnClosed];
        break;
    case KWSConnectionStatusOpen:
        [self closeWithCode:0 reason:nil];
    default:
        break;
    }
}

- (void)closeWithCode:(UInt16)code reason:(NSString*)reason
{
    DLOG(@"closeWithCode");
    [self.messageSender sendCloseFrameWithCode:code reason:reason];
    [self.rawConnection close];
    self.status = KWSConnectionStatusClosed;
    [self fireOnClosed];
}

- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    @autoreleasepool
    {
        switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            DLOG(@"NSStreamEventOpenCompleted");
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            DLOG(@"NSStreamEventHasBytesAvailable");

            if (self.status == KWSConnectionStatusConnecting) {
                KWSHandshakeResponse* resp = [[KWSHandshakeResponse alloc]
                    initFromStream:(NSInputStream*)stream];

                if (resp == nil) {
                    [self
                        fireOnError:
                            @"cannot initialize KWSHandshakeResponse from input stream"];
                    return;
                }

                self.handshakeReponse = resp;

                if (!self.onHandshakeResponseHandler(self)) {
                    [self fireOnError:@"cannot pass onHandshakeResponseHandler"];
                    return;
                }

                DLOG(@"WebSocket handshake success");
                self.status = KWSConnectionStatusOpen;

                if (self.onOpenHandler) {
                    BOOL ok = self.onOpenHandler(self);
                    if (!ok) {
                        DLOG(@"closed by onOpenHandler");
                        [self close];
                    }
                }
            }
            else if (self.status == KWSConnectionStatusOpen) {
                DLOG(@"current status KWSConnectionStatusOpen");
                KWSFrame* frame = [[KWSFrame alloc] initFromStream:self.rawConnection.inputStream
                                                     maxPayloadLen:self.frameMaxPayloadSize];

                DLOG(@"new frame arrived");
                if (frame) {
                    self.onFrameHandler(frame, self);
                }
                else {
                    [self fireOnError:@"cannot create frame"];
                }
            }

            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            DLOG(@"NSStreamEventHasSpaceAvailable");

            if (self.status == KWSConnectionStatusPending) {
                DLOG(@"current status KWSConnectionStatusPending");
                if (!self.onHandshakeRequestHandler(self)) {
                    [self fireOnError:@"cannot pass onHandshakeRequestHandler"];
                    return;
                }

                self.status = KWSConnectionStatusConnecting;
                return;
            }

            break;
        }
        default:
            break;
        }
    }
}

@end
