//
//  AppDelegate.h
//  CBTestMac
//
//  Created by Josh Rooke-Ley on 8/7/12.
//  Copyright (c) 2012 Josh Rooke-Ley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CanvasView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) CALayer *cursor;
@property (assign) IBOutlet NSWindow *window;
@property (assign) CanvasView *canvas;
@property (strong) NSMutableDictionary *brushes;

- (IBAction)clear:(id)sender;


@end
