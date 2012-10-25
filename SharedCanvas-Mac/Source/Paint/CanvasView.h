//
//  CanvasView.h
//  Paint
//

#import <Cocoa/Cocoa.h>
#import "Canvas.h"
#import "Brush.h"

@interface CanvasView : NSView

@property (strong) Canvas *canvas;


- (void)brushDown:(Brush *)brush point:(NSPoint )point;
- (void)brushDrag:(Brush *)brush point:(NSPoint )point;
- (void)brushUp:(Brush *)brush point:(NSPoint )point;

- (void)clear;

@end
