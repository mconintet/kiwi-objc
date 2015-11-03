//
//  NSURL+Util.h
//  kiwi
//
//  Created by mconintet on 10/8/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Util)
- (NSString*)resourceIdentifier;
- (NSString*)hostPort;
- (int)portAsInt;
@end
