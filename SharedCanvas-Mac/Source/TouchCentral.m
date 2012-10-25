//
//  TouchCentral.m
//  CBCentral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import "TouchCentral.h"

#import <IOBluetooth/IOBluetooth.h>
#import "../../TouchServiceSharedConstants.h"

NSString const *kTouchDeviceConnected = @"TouchDeviceConnected";
NSString const *kTouchDeviceDisconnected = @"TouchDeviceDisconnected";

static TouchCentral *__sharedTouchCentral;

@interface TouchCentral()<CBCentralManagerDelegate>
@property (strong) CBCentralManager *central;
//@property (strong) TouchDevice *touchDevice;
@property (strong) NSMutableArray *touchDevices;

@end

@implementation TouchCentral
{
    dispatch_queue_t _cbqueue;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cbqueue = dispatch_queue_create("com.rga.cb.touch", NULL);
        self.central = [[CBCentralManager alloc] initWithDelegate:self queue:_cbqueue];
        self.touchDevices = [NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

- (void)dealloc
{
    _cbqueue = nil;
}

- (void)startScan
{
    
    //NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:@1};
    //[self.central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TOUCH_SERVICE_UUID]] options:nil];
    [self.central scanForPeripheralsWithServices:nil options:nil];

}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
{
    NSLog(@"Core Bluetooth Did Update State: %ld",central.state);
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        //Good to go.
        NSLog(@"Bluetooth is powered up.");
        [self startScan];
    }
}

/*
 *  centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  Discussion:
 *      Invoked when the central discovered a peripheral while scanning.
 *      The advertisement / scan response data is stored in "advertisementData", and
 *      can be accessed through the CBAdvertisementData* keys.
 *      The peripheral must be retained if any command is to be performed on it.
 *
 */
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
{
    NSLog(@"Discovered Peripheral: %@ %@", peripheral.name, RSSI);
    
    //HACK: only connect to periperals' by name (only doing this because filtering the scan by service doesn't seem to be working)
    if ([peripheral.name isEqualTo:@"touch"])
    {
        TouchDevice *touchDevice = [[TouchDevice alloc] initWithPeripherial:peripheral];
        [self.touchDevices addObject:touchDevice];
        [central connectPeripheral:peripheral options:nil];
    }
    
}

/*
 *  centralManager:didConnectPeripheral:
 *
 *  Discussion:
 *      Invoked whenever a connection has been succesfully created with the peripheral.
 *
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
{
    
    NSLog(@"Connected to Peripheral: %@", peripheral.name);    
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)kTouchDeviceConnected object:nil];

    [peripheral discoverServices:@[[CBUUID UUIDWithString:TOUCH_SERVICE_UUID]]];
    
}

/*
 *  centralManager:didFailToConnectPeripheral:error:
 *
 *  Discussion:
 *      Invoked whenever a connection has failed to be created with the peripheral.
 *      The failure reason is stored in "error".
 *
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    NSLog(@"Failed to Connect to Peripheral: %@", peripheral.name);

}

/*
 *  centralManager:didDisconnectPeripheral:error:
 *
 *  Discussion:
 *      Invoked whenever an existing connection with the peripheral has been teared down.
 *
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    NSLog(@"Peripheral Disconnected: %@", peripheral.name);
    
    TouchDevice *deviceToRemove = nil;
    for (TouchDevice *device in self.touchDevices)
    {
        if ([device.cbPeripheral isEqualTo:peripheral])
        {
            deviceToRemove=device;
        }
    }
    if (!deviceToRemove)
    {
        NSLog(@"Got a disconnect message but could not find associated TouchDevice!");
        return;
    }
    
    NSString *uuidString = @"unknown";
    if (peripheral.UUID)
    {
        CFStringRef uuidStringRef = CFUUIDCreateString(nil, peripheral.UUID);
        uuidString = (NSString *)CFBridgingRelease(uuidStringRef);
    }
    
    [self.touchDevices removeObject:deviceToRemove];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)kTouchDeviceDisconnected object:nil
                                                      userInfo:@{kTouchEventNotificationUUIDKey:uuidString}];
    
}

+ (TouchCentral*)sharedInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{ __sharedTouchCentral = [[self alloc] init]; });
    return __sharedTouchCentral;
}

@end
