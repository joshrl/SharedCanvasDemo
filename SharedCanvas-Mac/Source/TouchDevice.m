//
//  TouchPeripherial.m
//  CBCentral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import "TouchDevice.h"

#import "../../TouchServiceSharedConstants.h"


NSString const *kTouchEventNotification = @"TouchEventNotification";
NSString const *kTouchEventNotificationPointKey = @"TouchEventNotificationPointKey";
NSString const *kTouchEventNotificationPhaseKey = @"TouchEventNotificationPhaseKey";
NSString const *kTouchEventNotificationUUIDKey = @"TouchEventNotificationUUIDKey";

@interface TouchDevice ()<CBPeripheralDelegate>
@property (strong, readwrite) CBPeripheral *cbPeripheral;
@end

@implementation TouchDevice
{
    CBUUID *tapUUID;
    CBUUID *touchEventUUID;
}
- (id)initWithPeripherial:(CBPeripheral *)periph;
{
    self = [super init];
    if (self) {
        self.cbPeripheral = periph;
        self.cbPeripheral.delegate = self;
        tapUUID = [CBUUID UUIDWithString:TAP_GESTURE_CHARACTERISTIC_UUID];
        touchEventUUID = [CBUUID UUIDWithString:TOUCH_EVENT_CHARACTERISTIC_UUID];
    }
    return self;
}



- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error;
{
    
    NSLog(@"Updated RSSI: %@",peripheral.RSSI);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        NSLog(@"Discovered characteristics for service: %@ periph: %@", service.UUID, peripheral.UUID);
        
        for (CBCharacteristic *c in service.characteristics)
        {
            NSLog(@"  characteristic: %@",c.UUID);
            
            if ([c.UUID isEqualTo:tapUUID])
            {
                NSLog(@"Found tap characteristic, subscribing...");
                [peripheral setNotifyValue:YES forCharacteristic:c];
            }
            else if ([c.UUID isEqualTo:touchEventUUID])
            {
                NSLog(@"Found touch event characteristic, subscribing...");
                [peripheral setNotifyValue:YES forCharacteristic:c];
                
                
            }
        }
        
        
    }
    else {
        NSLog(@"Service discovery failed for service: %@ periph: %@", service, peripheral.UUID);
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error;
{
    if (!error)
    {
        NSLog(@"Discovered service for peripheral: %@", peripheral.name);
        for (CBService *service in peripheral.services)
        {
            //NSArray *characteristics = @[tapUUID];
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    else {
        NSLog(@"Service discovery failed for peripheral: %@", peripheral.name);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if ([characteristic.UUID isEqualTo:touchEventUUID])
    {
        NSData *payload = characteristic.value;
        uint16_t bytes[3];
        [payload getBytes:&bytes];
        
        NSPoint point = NSMakePoint(bytes[1]/(float)UINT16_MAX, bytes[2]/(float)UINT16_MAX);
        NSValue *pointObj = [NSValue valueWithPoint:point];
        NSNumber *phase = [NSNumber numberWithInt:bytes[0]];
        
        NSString *uuidString = @"unknown";
        
        if (peripheral.UUID)
        {
            CFStringRef uuidStringRef = CFUUIDCreateString(nil, peripheral.UUID);
            uuidString = (NSString *)CFBridgingRelease(uuidStringRef);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)kTouchEventNotification object:nil
                                                          userInfo:@{kTouchEventNotificationPhaseKey:phase,kTouchEventNotificationPointKey:pointObj,kTouchEventNotificationUUIDKey:uuidString}];
        
        
        //NSLog(@"%d %f %f", bytes[0],bytes[1]/(float)UINT16_MAX,bytes[2]/(float)UINT16_MAX);
    }
    
}


@end
