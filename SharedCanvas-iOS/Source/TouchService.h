//
//  TouchService.h
//  CBPeripheral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const kTouchCenralConnectedNotification;
extern NSString * const kTouchCentralDisconnectedNotification;


@interface TouchService : UIResponder
{

}
@property BOOL isConnected;
@property (strong) UIView *view;

- (void)advertise;
+ (TouchService*)sharedInstance;

@end
