//
//  KWSMessage.h
//  kiwi
//
//  Created by mconintet on 10/10/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWSFrame.h"

@interface KWSMessage : NSObject
@property (nonatomic, assign) NSInteger opcode;
@property (nonatomic, strong) NSMutableData* data;

@property (nonatomic, assign, readonly) BOOL isFilled;

// return true if message gets all it's frame
- (void)appendFrame:(KWSFrame*)frame;

// it's caller's responsibility to release the return value
- (NSString*)newString;
@end
