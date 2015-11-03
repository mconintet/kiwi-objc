//
//  kiwiTests.m
//  kiwiTests
//
//  Created by mconintet on 10/7/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KWSHeader.h"
#import "KWSHandshakeResponse.h"
#import "KWSConnection.h"

@interface kiwiTests : XCTestCase

@end

@implementation kiwiTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testKWSHandshakeResponse
{
    NSString* resp = @"HTTP/1.1 200 OK\r\n"
                      "Host: stackoverflow.com\r\n"
                      "Connection: keep-alive\r\n"
                      "Pragma: no-cache\r\n"
                      "Cache-Control: no-cache\r\n"
                      "\r\n";

    NSInputStream* stream = [[NSInputStream alloc] initWithData:[resp dataUsingEncoding:NSUTF8StringEncoding]];
    [stream open];
    KWSHandshakeResponse* kr = [[KWSHandshakeResponse alloc] initFromStream:stream];
    XCTAssertTrue(kr != nil, @"kr");

    KWSHeader* header = kr.header;
    NSString* host = [header getValueWithKey:@"Host"];
    XCTAssertTrue([host isEqualToString:@"stackoverflow.com"], @"host: '%@'", host);

    XCTAssertTrue([header hasKeyAndValueEquals:@"Connection" value:@"keep-alive"], @"Connection: '%@'", host);
    XCTAssertTrue([header hasKeyAndValContains:@"Pragma" value:@"no-cache"], @"Pragma: '%@'", host);
}

- (void)testKWSHeader
{
    NSString* req = @"Host: stackoverflow.com\r\n"
                     "Connection: keep-alive\r\n"
                     "Pragma: no-cache\r\n"
                     "Cache-Control: no-cache\r\n";

    NSData* d = [req dataUsingEncoding:NSUTF8StringEncoding];
    KWSHeader* header = [[KWSHeader alloc] initWithBytes:(uint8_t*)[d bytes] length:[d length] isCRLF:true];

    NSString* host = [header getValueWithKey:@"Host"];
    XCTAssertTrue([host isEqualToString:@"stackoverflow.com"], @"host: '%@'", host);

    XCTAssertTrue([header hasKeyAndValueEquals:@"Connection" value:@"keep-alive"], @"Connection: '%@'", host);
    XCTAssertTrue([header hasKeyAndValContains:@"Pragma" value:@"no-cache"], @"Pragma: '%@'", host);

    d = [header data];
    header = [[KWSHeader alloc] initWithBytes:(uint8_t*)[d bytes] length:[d length] isCRLF:true];
    XCTAssertTrue(header != nil, @"data");

    XCTAssertNotEqual([header UTF8String], @"");
    DLOG(@"%@", [header UTF8String]);
}

- (void)testKWSConnectionHandshake
{
    NSURL* url = [NSURL URLWithString:@"ws://echo.websocket.org"];
    KWSConnection* conn = [[KWSConnection alloc] initWithURL:url];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    __block BOOL ok = false;
    conn.onOpenHandler = ^BOOL(KWSConnection* conn) {
        DLOG(@"onOpenHandler");
        ok = true;
        dispatch_semaphore_signal(semaphore);
        [conn.rawConnection close];
        return true;
    };

    conn.onErrorHandler = ^(NSError* err) {
        DLOG(@"onErrorHandler:%@", err);
        dispatch_semaphore_signal(semaphore);
    };

    [conn connectWithTimeout:10];
    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:50]];

    XCTAssertTrue(ok, @"testKWSConnectionHandshake");
}

- (void)testNSMutableData
{
    uint8_t buf[2] = { 1, 2 };
    NSMutableData* data = [NSMutableData dataWithBytes:buf length:2];
    uint8_t* buf2 = (uint8_t*)[data bytes];
    buf2[1] = 3;

    buf2 = (uint8_t*)[(NSData*)data bytes];
    DLOG(@"%d", buf2[1]);
    XCTAssertTrue(buf2[1] == 3, @"testNSMutableData");
}

- (void)testEcho
{
    NSURL* url = [NSURL URLWithString:@"ws://127.0.0.1:9876"];
    KWSConnection* conn = [[KWSConnection alloc] initWithURL:url];

    NSString* testStr = @"kiwi testEcho";

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    conn.onOpenHandler = ^BOOL(KWSConnection* conn) {
        DLOG(@"onOpenHandler");
        BOOL ok = [conn.messageSender sendWithString:testStr];
        if (!ok) {
            dispatch_semaphore_signal(semaphore);
        }
        return ok;
    };

    __block BOOL ok = false;
    conn.onMessageHandler = ^BOOL(KWSMessage* msg, KWSConnection* conn) {
        DLOG(@"onMessageHandler");
        NSString* msgStr = [msg newString];
        DLOG(@"received msg: %@", msgStr);
        ok = [msgStr isEqualToString:testStr];
        [conn close];
        return true;
    };

    conn.onClosedHandler = ^(void) {
        DLOG(@"onClosedHandler");
        dispatch_semaphore_signal(semaphore);
    };

    conn.onErrorHandler = ^(NSError* err) {
        DLOG(@"onErrorHandler:%@", err);
        dispatch_semaphore_signal(semaphore);
    };

    conn.onTimeoutHandler = ^(void) {
        DLOG(@"connection timeout");
    };

    [conn connectWithTimeout:10];
    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    XCTAssertTrue(ok, @"testEcho");
}

//- (void)testPerformanceExample
//{
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
