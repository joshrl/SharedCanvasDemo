//
//  TouchCentral.h
//  CBCentral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TouchDevice.h"

extern NSString const *kTouchDeviceConnected;
extern NSString const *kTouchDeviceDisconnected;

@interface TouchCentral : NSObject

+ (TouchCentral*)sharedInstance;

@end
