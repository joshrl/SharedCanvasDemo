//
//  Brush.m
//  Paint
//

#import "Brush.h"
#import "Canvas.h"
#import <QuartzCore/QuartzCore.h>

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef
                                            colorSpace, NSColor *color)
{
    NSColor *deviceColor = [color colorUsingColorSpaceName:
                            NSDeviceRGBColorSpace];
    
    CGFloat components[4];
    [deviceColor getRed: &components[0] green: &components[1] blue:
     &components[2] alpha: &components[3]];
    
    return CGColorCreate (colorSpace, components);
}


@interface Brush (Private)

- (NSPoint) canvasLocation:(NSEvent *)theEvent view:(NSView *)view;
- (void) stampStart:(NSPoint)startPoint end:(NSPoint)endPoint inView:(NSView *)view onCanvas:(Canvas *)canvas;

- (CGContextRef) createBitmapContext;
- (void) disposeBitmapContext:(CGContextRef)bitmapContext;
- (CGImageRef) createShapeImage;

@end

@implementation Brush


- (id) initWithBrushSize:(float)diameter
                softness:(float)softness
                   alpha:(float)alpha
                   color:(NSColor *)color
{
	self = [super init];
	
	if ( self ) {
		mRadius = diameter;
		
		// Create the shape of the tip of the brush. Code currently assumes the bounding
		//	box of the shape is square (height == width)
		mShape = CGPathCreateMutable();
		CGPathAddEllipseInRect(mShape, nil, CGRectMake(0, 0, 2 * mRadius, 2 * mRadius));
		//CGPathAddRect(mShape, nil, CGRectMake(0, 0, 2 * mRadius, 2 * mRadius));
        
		// Create the color for the brush
		CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		//float components[] = { 1.0, 1.0, 1.0, 1.0 };
		mColor = CGColorCreateFromNSColor(colorspace,color);//CGColorCreate(colorspace, components);
		CGColorSpaceRelease(colorspace);
        
		// The "softness" of the brush edges
		mSoftness = softness;
		
		// Initialize variables that will be used during tracking
		mMask = nil;
		mLastPoint = NSZeroPoint;
		mLeftOverDistance = 0.0;
	}
	
	return self;
}


- (id) init
{
	self = [super init];
	
	if ( self ) {
		mRadius = 10.0;
		
		// Create the shape of the tip of the brush. Code currently assumes the bounding
		//	box of the shape is square (height == width)
		mShape = CGPathCreateMutable();
		CGPathAddEllipseInRect(mShape, nil, CGRectMake(0, 0, 2 * mRadius, 2 * mRadius));
		//CGPathAddRect(mShape, nil, CGRectMake(0, 0, 2 * mRadius, 2 * mRadius));

		// Create the color for the brush
		CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		CGFloat components[] = { 0.0, 0.0, 1.0, 1.0 }; // I like blue
		mColor = CGColorCreate(colorspace, components);
		CGColorSpaceRelease(colorspace);

		// The "softness" of the brush edges
		mSoftness = 0.5;
		mHard = NO;
		
		// Initialize variables that will be used during tracking
		mMask = nil;
		mLastPoint = NSZeroPoint;
		mLeftOverDistance = 0.0;
	}
	
	return self;
}

- (void) dealloc
{
	// Clean up our shape and color
	CGPathRelease(mShape);
	CGColorRelease(mColor);
	
}



- (void) brushDownAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    NSPoint currentPoint = [view convertPoint:p fromView:nil];
    // Initialize all the tracking information. This includes creating an image
	//	of the brush tip
	mMask = [self createShapeImage];
	mLastPoint = currentPoint;
	mLeftOverDistance = 0.0;
	
	// Since this is a mouse down, we want to stamp the brush's image not matter
	//	what.
	[canvas stampMask:mMask at:currentPoint];
	
	// This isn't very efficient, but we need to tell the view to redraw. A better
	//	version would have the canvas itself to generate an invalidate for the view
	//	(since it knows exactly where the bits changed).
	[view setNeedsDisplay:YES];
}


- (void) brushDraggedAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    // Translate the event point location into a canvas point
    NSPoint currentPoint = [view convertPoint:p fromView:nil];
	
	// Stamp the brush in a line, from the last mouse location to the current one
	[self stampStart:mLastPoint end:currentPoint inView:view onCanvas:canvas];
	
	// Remember the current point, so that next time we know where to start
	//	the line
	mLastPoint = currentPoint;
}

- (void) brushUpAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    // Translate the event point location into a canvas point
    NSPoint currentPoint = [view convertPoint:p fromView:nil];
	
	// Stamp the brush in a line, from the last mouse location to the current one
	[self stampStart:mLastPoint end:currentPoint inView:view onCanvas:canvas];
	
	// This is a mouse up, so we are done tracking. Use this opportunity to clean
	//	up all the tracking information, including the brush tip image.
	CGImageRelease(mMask);
	mMask = nil;
	mLastPoint = NSZeroPoint;
	mLeftOverDistance = 0.0;
}

- (void) mouseDown:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    
    NSPoint eventLocation = [theEvent locationInWindow];
    [self brushDownAtPointInWindow:eventLocation inView:view onCanvas:canvas];
    
}

- (void) mouseDragged:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    
    NSPoint eventLocation = [theEvent locationInWindow];
    [self brushDraggedAtPointInWindow:eventLocation inView:view onCanvas:canvas];
    
}

- (void) mouseUp:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas
{
    
    NSPoint eventLocation = [theEvent locationInWindow];
    [self brushUpAtPointInWindow:eventLocation inView:view onCanvas:canvas];
}

@end

@implementation Brush (Private)

- (NSPoint) canvasLocation:(NSEvent *)theEvent view:(NSView *)view
{
	// Currently we assume that the NSView here is a CanvasView, which means
	//	that the view is not scaled or offset. i.e. There is a one to one
	//	correlation between the view coordinates and the canvas coordinates.
	NSPoint eventLocation = [theEvent locationInWindow];
	return [view convertPoint:eventLocation fromView:nil];
}

- (void) stampStart:(NSPoint)startPoint end:(NSPoint)endPoint inView:(NSView *)view onCanvas:(Canvas *)canvas
{
	// We need to ask the canvas to draw a line using the brush. Keep track
	//	of the distance left over that we didn't draw this time (so we draw
	//	it next time).
	mLeftOverDistance = [canvas stampMask:mMask from:startPoint to:endPoint leftOverDistance:mLeftOverDistance];
	
	// This isn't very efficient, but we need to tell the view to redraw. A better
	//	version would have the canvas itself to generate an invalidate for the view
	//	(since it knows exactly where the bits changed).	
	[view setNeedsDisplay:YES];
}

- (CGContextRef) createBitmapContext
{
	// Create the offscreen bitmap context that we can draw the brush tip into.
	//	The context should be the size of the shape bounding box.
	CGRect boundingBox = CGPathGetBoundingBox(mShape);
	
	size_t width = CGRectGetWidth(boundingBox);
	size_t height = CGRectGetHeight(boundingBox);
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = ((width * 4) + 0x0000000F) & ~0x0000000F; // 16 byte aligned is good
	size_t dataSize = bytesPerRow * height;
	void* data = calloc(1, dataSize);
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	CGContextRef bitmapContext = CGBitmapContextCreate(data, width, height, bitsPerComponent,
													   bytesPerRow, colorspace, 
													   kCGImageAlphaPremultipliedFirst);
	
	CGColorSpaceRelease(colorspace);

	// Clear the context to transparent, 'cause we'll be using transparency
	CGContextClearRect(bitmapContext, CGRectMake(0, 0, width, height));
	
	return bitmapContext;
}

- (void) disposeBitmapContext:(CGContextRef)bitmapContext
{
	// Free up the offscreen bitmap
	void * data = CGBitmapContextGetData(bitmapContext);
	CGContextRelease(bitmapContext);
	free(data);	
}

- (CGImageRef) createShapeImage
{
	// Create a bitmap context to hold our brush image
	CGContextRef bitmapContext = [self createBitmapContext];
	
	// If we're not going to have a hard edge, set the alpha to 50% (using a
	//	transparency layer) so the brush strokes fade in and out more.
	if ( !mHard )
		CGContextSetAlpha(bitmapContext, 0.5);
	CGContextBeginTransparencyLayer(bitmapContext, nil);
	
	// I like a little color in my brushes
	CGContextSetFillColorWithColor(bitmapContext, mColor);
	
	// The way we acheive "softness" on the edges of the brush is to draw
	//	the shape full size with some transparency, then keep drawing the shape
	//	at smaller sizes with the same transparency level. Thus, the center
	//	builds up and is darker, while edges remain partially transparent.
	
	// First, based on the softness setting, determine the radius of the fully
	//	opaque pixels.
	int innerRadius = (int)ceil(mSoftness * (0.5 - mRadius) + mRadius);
	int outerRadius = (int)ceil(mRadius);
	int i = 0;
	
	// The alpha level is always proportial to the difference between the inner, opaque
	//	radius and the outer, transparent radius.
	float alphaStep = 1.0 / (outerRadius - innerRadius + 1);
	
	// Since we're drawing shape on top of shape, we only need to set the alpha once
	CGContextSetAlpha(bitmapContext, alphaStep);
	
	for (i = outerRadius; i >= innerRadius; --i) {
		CGContextSaveGState(bitmapContext);
		
		// First, center the shape onto the context.
		CGContextTranslateCTM(bitmapContext, outerRadius - i, outerRadius - i);

		// Second, scale the the brush shape, such that each successive iteration
		//	is two pixels smaller in width and height than the previous iteration.
		float scale = (2.0 * (float)i) / (2.0 * (float)outerRadius);
		CGContextScaleCTM(bitmapContext, scale, scale);

		// Finally, actually add the path and fill it
		CGContextAddPath(bitmapContext, mShape);
		CGContextEOFillPath(bitmapContext);

		CGContextRestoreGState(bitmapContext);
	}
	
	// We're done drawing, composite the tip onto the context using whatever
	//	alpha we had set up before BeginTransparencyLayer.
	CGContextEndTransparencyLayer(bitmapContext);
	
	// Create the brush tip image from our bitmap context
	CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
	
	// Free up the offscreen bitmap
	[self disposeBitmapContext:bitmapContext];
	
	return image;
}


@end
