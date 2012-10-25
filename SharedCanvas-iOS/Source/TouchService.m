//
//  TouchService.m
//  CBPeripheral
//
//  Created by Josh Rooke-Ley on 8/27/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import "TouchService.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "../../TouchServiceSharedConstants.h"


NSString * const kTouchCenralConnectedNotification = @"kTouchCenralConnectedNotification";
NSString * const kTouchCentralDisconnectedNotification = @"kTouchCentralDisconnectedNotification";

static TouchService *__sharedTouchService = nil;

@interface TouchService() <CBPeripheralManagerDelegate>
{
    __strong UIView *_view;
}
@property (strong) CBPeripheralManager *manager;
@property (strong) CBMutableService *service;
@property (strong) CBMutableCharacteristic *touchEventCharacteristic;
@property (strong) CBMutableCharacteristic *tapCharacteristic;
@property (strong) NSArray *gestureRecognizers;
@property (strong) NSMutableSet *connectedCentrals;

@property (strong) NSArray *characteristics;
@end

@implementation TouchService
dispatch_queue_t _cbqueue;


- (void)dealloc
{
    _cbqueue = nil;
}


- (id)init
{
    self = [super init];
    if (self) {
        _cbqueue = dispatch_queue_create("com.rga.cb.touch", NULL);
        self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_cbqueue];
        self.connectedCentrals = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - View + UIGestureRecognizers

- (UIView *)view
{
    return _view;
}

- (void)setView:(UIView *)view
{
    if (_view != nil) {
        for (UIGestureRecognizer *gr in self.gestureRecognizers) {
            [_view removeGestureRecognizer:gr];
        }
        _view = nil;
    }
    _view = view;
    UITapGestureRecognizer *singleTapRecogonizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    singleTapRecogonizer.numberOfTapsRequired = 1;
    [view addGestureRecognizer:singleTapRecogonizer];
    
    //Add other recognizers here...
    
    //retain all gesture recongizers so they can be removed
    self.gestureRecognizers = @[singleTapRecogonizer];

}

- (void)onTap:(UITapGestureRecognizer *)gr
{
    uint8_t numTaps = (uint8_t) gr.numberOfTapsRequired;
    NSData *payload = [NSData dataWithBytes:&numTaps length:sizeof(numTaps)];
    [self.manager updateValue:payload forCharacteristic:self.tapCharacteristic onSubscribedCentrals:nil];
}


#pragma mark - Util

- (NSData *)packTouchEvent:(UITouch *)touch
{
    CGPoint p = [touch locationInView:self.view];
    
    uint16_t phase = touch.phase;
    uint16_t x = (p.x/self.view.bounds.size.width)*UINT16_MAX;
    uint16_t y = (p.y/self.view.bounds.size.height)*UINT16_MAX;
    uint16_t bytes[] = {phase,x,y};
    return [NSData dataWithBytes:&bytes length:sizeof(bytes)];
}

#pragma mark - Touch Events + UIResponder

- (BOOL)canBecomeFirstResponder {return YES;}
- (BOOL)isFirstResponder {return YES;}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    NSLog(@"touchesBegan");

    UITouch *touch = [touches anyObject];
    NSData *payload = [self packTouchEvent:touch];
    [self.manager updateValue:payload forCharacteristic:self.touchEventCharacteristic onSubscribedCentrals:nil];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NSData *payload = [self packTouchEvent:touch];
    [self.manager updateValue:payload forCharacteristic:self.touchEventCharacteristic onSubscribedCentrals:nil];
    

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded");
    UITouch *touch = [touches anyObject];
    NSData *payload = [self packTouchEvent:touch];
    [self.manager updateValue:payload forCharacteristic:self.touchEventCharacteristic onSubscribedCentrals:nil];

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesCancelled");
    
    UITouch *touch = [touches anyObject];
    NSData *payload = [self packTouchEvent:touch];
    [self.manager updateValue:payload forCharacteristic:self.touchEventCharacteristic onSubscribedCentrals:nil];

}


#pragma mark - 1. Publish Service 

- (void)publishService
{
    if (!self.service) {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:TOUCH_SERVICE_UUID];
        self.service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
        
        self.tapCharacteristic = [[CBMutableCharacteristic alloc]
                                  initWithType:[CBUUID UUIDWithString:TAP_GESTURE_CHARACTERISTIC_UUID]
                                  properties:CBCharacteristicPropertyNotify
                                  value:nil
                                  permissions:0];
        
        self.touchEventCharacteristic = [[CBMutableCharacteristic alloc]
                                         initWithType:[CBUUID UUIDWithString:TOUCH_EVENT_CHARACTERISTIC_UUID]
                                         properties:CBCharacteristicPropertyNotify
                                         value:nil
                                         permissions:0];
        
        //Add more characteristics here.
        
        NSArray *characteristics = @[self.touchEventCharacteristic,self.tapCharacteristic];
        
        self.service.characteristics = characteristics;
    }
    [self.manager removeService:self.service];
    [self.manager addService:self.service];
    

    
}

#pragma mark - 2. Advertise Service

- (void)advertise
{
    NSArray *services = @[[CBUUID UUIDWithString:TOUCH_SERVICE_UUID]];
    NSDictionary *advertDictionary = @{CBAdvertisementDataLocalNameKey:@"touch",CBAdvertisementDataServiceUUIDsKey:services};
    [self.manager startAdvertising:advertDictionary];
}

//- (void)stopAdverising
//{
//    [self.manager stopAdvertising];
//}

#pragma mark - 3. Interact with Central


#pragma mark - CBPeripheralManagerDelegate Methods 

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral;
{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"Bluetooth is on!");
            [self publishService];
            break;
            
        default:
            
            NSLog(@"Peripheral manager changed state: %d", peripheral.state);
            break;
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        NSLog(@"Touch Service Added Service!");
        
        //Immediately start advertising...
        
        [self advertise];
    }
    else {
        NSLog(@"Touch Service Failed to Add Service: %@", [error localizedDescription]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    
    if (!error)
    {
        NSLog(@"Touch Service Started Advertising!");
    }
    else {
        NSLog(@"Touch Service Failed to Start Advertising: %@", [error localizedDescription]);
    }
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    if (![self.connectedCentrals containsObject:(__bridge id)central.UUID])
    {
        [peripheral setDesiredConnectionLatency:CBPeripheralManagerConnectionLatencyLow forCentral:central];
        NSLog(@"Got a subscriber: %@",central.UUID);
        [self.connectedCentrals addObject:(__bridge id)central.UUID];
        self.isConnected = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTouchCenralConnectedNotification object:nil];
        });
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    if ([self.connectedCentrals containsObject:(__bridge id)central.UUID])
    {
        NSLog(@"Got a unsubscriber: %@",central.UUID);
        [self.connectedCentrals removeObject:(__bridge id)central.UUID];
        self.isConnected = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTouchCentralDisconnectedNotification object:nil];
        });
    }
}

#pragma mark -
#pragma mark Singleton

+ (TouchService*)sharedInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{ __sharedTouchService = [[self alloc] init]; });
    return __sharedTouchService;
}

@end
