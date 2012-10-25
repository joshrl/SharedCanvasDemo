//
//  AppDelegate.m
//  CBTestMac
//
//  Created by Josh Rooke-Ley on 8/7/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "TouchCentral.h"
#import "Brush.h"

//Touch Phases (grabbed from UIKit)
typedef NS_ENUM(NSInteger, UITouchPhase) {
    UITouchPhaseBegan,             // whenever a finger touches the surface.
    UITouchPhaseMoved,             // whenever a finger moves on the surface.
    UITouchPhaseStationary,        // whenever a finger is touching the surface but hasn't moved since the previous event.
    UITouchPhaseEnded,             // whenever a finger leaves the surface.
    UITouchPhaseCancelled,         // whenever a touch doesn't end but we need to stop tracking (e.g. putting device to face)
};

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"App did launch");
    [TouchCentral sharedInstance];
    self.brushes = [NSMutableDictionary dictionary];
            
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTouchEvent:) name:(NSString *)kTouchEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceDisconnect:) name:(NSString *)kTouchDeviceDisconnected object:nil];


    CanvasView *canvas = [[CanvasView alloc] initWithFrame:[self.window.contentView bounds]];
    [canvas setTranslatesAutoresizingMaskIntoConstraints:NO];

    [[self.window contentView] addSubview:canvas];
    
    [[[self window] contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[canvas]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(canvas)]];
    [[[self window] contentView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[canvas]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(canvas)]];
    
    self.canvas = canvas;
    
    self.cursor = [CALayer layer];
    self.cursor.frame = CGRectZero;
    self.cursor.backgroundColor = [NSColor redColor].CGColor;

    [self.canvas setWantsLayer:YES];
    [[self.canvas layer] addSublayer:self.cursor];
    
}

- (NSColor *)randomColor
{
    NSColorList *colorList = [NSColorList colorListNamed:@"Crayons"];
    NSArray *keys = [colorList allKeys];
    NSUInteger randomIndex = arc4random() % [keys count];
    NSColor *color = [colorList colorWithKey:[keys objectAtIndex:randomIndex]];
    return color;
}

- (void)onTouchEvent:(NSNotification *)n
{
    NSInteger phase = [[[n userInfo] objectForKey:kTouchEventNotificationPhaseKey] integerValue];
    NSPoint relativePoint = [(NSValue *)[[n userInfo] objectForKey:kTouchEventNotificationPointKey] pointValue];
    NSString *uuid = [[n userInfo] objectForKey:kTouchEventNotificationUUIDKey];
    
    Brush *brush = [self.brushes objectForKey:uuid];
    if (!brush)
    {
        brush = [[Brush alloc] initWithBrushSize:10. softness:2. alpha:1. color:[self randomColor]];
        [self.brushes setObject:brush forKey:uuid];
    }
    
    NSPoint pointInWindow = NSMakePoint(self.window.frame.size.width*relativePoint.x, self.window.frame.size.height-(self.window.frame.size.height*relativePoint.y));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        switch (phase) {
            case UITouchPhaseBegan:
                
                self.cursor.hidden = NO;
                [self moveCursorToPoint:pointInWindow];
                [self.canvas brushDown:brush point:pointInWindow];
                break;
            case UITouchPhaseMoved:
                
                [self moveCursorToPoint:pointInWindow];
                [self.canvas brushDrag:brush point:pointInWindow];
                break;
                
            case UITouchPhaseStationary:
                
                break;
                
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                self.cursor.hidden = YES;
                [self.canvas brushUp:brush point:pointInWindow];
                break;
                
            default:
                break;
        }
        
    });

}

- (void)moveCursorToPoint:(NSPoint)p
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.cursor.frame = CGRectMake(p.x, p.y, 3, 3);
    [CATransaction commit];
}



- (IBAction)clear:(id)sender {
    [self.canvas clear];
    self.brushes = [NSMutableDictionary dictionary];
    
}

- (void)onDeviceDisconnect:(NSNotification *)n
{
    NSString *uuid = [[n userInfo] objectForKey:kTouchEventNotificationUUIDKey];
    if (uuid)
    {
        NSLog(@"Removing brush for device: %@",uuid);
        [self.brushes removeObjectForKey:uuid];
    }
}

@end
