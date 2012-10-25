//
//  TouchPeripherial.h
//  CBCentral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

extern NSString const *kTouchEventNotification;
extern NSString const *kTouchEventNotificationPointKey;
extern NSString const *kTouchEventNotificationPhaseKey;
extern NSString const *kTouchEventNotificationUUIDKey;

@interface TouchDevice : NSObject

- (id)initWithPeripherial:(CBPeripheral *)periph;
@property (strong, readonly) CBPeripheral *cbPeripheral;

@end
