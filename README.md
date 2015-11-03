## About

Client component of WebSocket in Objective-C. It can communicate with websocket service without using UIWebView.

## Usage

```objc
NSURL* url = [NSURL URLWithString:@"ws://your_websocket_service_address"];
KWSConnection* conn = [[KWSConnection alloc] initWithURL:url];

// setup custom handlers
conn.onOpenHandler = ^BOOL(KWSConnection* conn) {
	[conn.messageSender sendWithString:@"Hello"];
	// return false if you want to close conn after message sent
	return true;
};

conn.onMessageHandler = ^BOOL(KWSMessage* msg, KWSConnection* conn) {
    NSString* msgStr = [msg newString];
    NSLog(@"received msg: %@", msgStr);
    // return false if you want to close conn after message received
    return true;
};

conn.onClosedHandler = ^(void) {
    NSLog(@"connection closed");
};

// you can do some works after any error occured
// conn will be closed automaticlly after your custom onErrorHandler performed
conn.onErrorHandler = ^(NSError* err) {
    NSLog(@"onErrorHandler: %@", err);
};

conn.onTimeoutHandler = ^(void) {
    NSLog(@"connection timeout");
};

// try to connect to service with a timeout value
[conn connectWithTimeout:10];
// run in RunLoop
[conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
```

## Installation

```
// in your pod file
pod 'kiwi-objc', :git => 'https://github.com/mconintet/kiwi-objc.git'
```

```
// command line
pod install
```