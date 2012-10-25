//
//  Canvas.h
//  Paint
//


#import <Cocoa/Cocoa.h>


@interface Canvas : NSObject {
	// The canvas is simply backed by a bitmap context. A CGLayerRef would be
	//	better, but you have to know your destination context before you create
	//	it (which we don't).
	CGContextRef	mBitmapContext;
}

// Constructor that creates a canvas at the specified size. Canvas cannot be resized.
- (id) initWithSize:(NSSize)size;

// Draws the contents of the canvas into the specified context. Handy for views
//	that host a canvas.
- (void)drawRect:(NSRect)rect inContext:(NSGraphicsContext*)context;

// Graphics privimites for the canvas. The first draws a line given the brush
//	image, and the second, draws a point given the brush image.
- (float)stampMask:(CGImageRef)mask from:(NSPoint)startPoint to:(NSPoint)endPoint leftOverDistance:(float)leftOverDistance;
- (void)stampMask:(CGImageRef)mask at:(NSPoint)point;

@end
