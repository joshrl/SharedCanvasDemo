//
//  Canvas.m
//  Paint
//


#import "Canvas.h"

@implementation Canvas

- (id) initWithSize:(NSSize)size
{
	self = [super init];
	
	if ( self ) {
		// Create a bitmap context for the canvas. To keep things simple
		//	we're going to use a 32-bit ARGB format.
		size_t width = size.width;
		size_t height = size.height;
		size_t bitsPerComponent = 8;
		size_t bytesPerRow = ((width * 4) + 0x0000000F) & ~0x0000000F; // 16-byte aligned is good
		size_t dataSize = bytesPerRow * height;
		void* data = calloc(1, dataSize);
		CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		
		mBitmapContext = CGBitmapContextCreate(data, width, height, bitsPerComponent,
											  bytesPerRow, colorspace, 
											  kCGImageAlphaPremultipliedFirst);
		
		CGColorSpaceRelease(colorspace);
		
		// Paint on a white background so the user has something to start with.
		CGContextSaveGState(mBitmapContext);
		
		CGRect fillRect = CGRectMake(0, 0, CGBitmapContextGetWidth(mBitmapContext), 
									  CGBitmapContextGetHeight(mBitmapContext));

		CGContextSetRGBFillColor(mBitmapContext, 1.0, 1.0, 1.0, 1.0);
		CGContextFillRect(mBitmapContext, fillRect);
		
		CGContextRestoreGState(mBitmapContext);
	}
	
	return self;
}

- (void) dealloc
{
	// Free up our bitmap context
	void* data = CGBitmapContextGetData(mBitmapContext);
	CGContextRelease(mBitmapContext);
	free(data);
	
}

- (void)drawRect:(NSRect)rect inContext:(NSGraphicsContext*)context
{
	// Here we simply want to render our bitmap context into the view's
	//	context. It's going to be a straight forward bit blit. First,
	//	create an image from our bitmap context.
	CGImageRef imageRef = CGBitmapContextCreateImage(mBitmapContext);
	
	// Grab the destination context
	CGContextRef contextRef = [context graphicsPort];
	CGContextSaveGState(contextRef);

	// Composite on the image at the bottom left of the context
	CGRect imageRect = CGRectMake(0, 0, CGBitmapContextGetWidth(mBitmapContext), 
								  CGBitmapContextGetHeight(mBitmapContext));
	CGContextDrawImage(contextRef, imageRect, imageRef);
	
	CGImageRelease(imageRef);
	
	CGContextRestoreGState(contextRef);
}

- (float)stampMask:(CGImageRef)mask from:(NSPoint)startPoint to:(NSPoint)endPoint leftOverDistance:(float)leftOverDistance
{
	// Set the spacing between the stamps. By trail and error, I've 
	//	determined that 1/10 of the brush width (currently hard coded to 20)
	//	is a good interval.
	float spacing = CGImageGetWidth(mask) * 0.1;
	
	// Anything less that half a pixel is overkill and could hurt performance.
	if ( spacing < 0.5 )
		spacing = 0.5;
	
	// Determine the delta of the x and y. This will determine the slope
	//	of the line we want to draw.
	float deltaX = endPoint.x - startPoint.x;
	float deltaY = endPoint.y - startPoint.y;
	
	// Normalize the delta vector we just computed, and that becomes our step increment
	//	for drawing our line, since the distance of a normalized vector is always 1
	float distance = sqrt( deltaX * deltaX + deltaY * deltaY );
	float stepX = 0.0;
	float stepY = 0.0;
	if ( distance > 0.0 ) {
		float invertDistance = 1.0 / distance;
		stepX = deltaX * invertDistance;
		stepY = deltaY * invertDistance;
	}
	
	float offsetX = 0.0;
	float offsetY = 0.0;
	
	// We're careful to only stamp at the specified interval, so its possible
	//	that we have the last part of the previous line left to draw. Be sure
	//	to add that into the total distance we have to draw.
	float totalDistance = leftOverDistance + distance;
	
	// While we still have distance to cover, stamp
	while ( totalDistance >= spacing ) {
		// Increment where we put the stamp
		if ( leftOverDistance > 0 ) {
			// If we're making up distance we didn't cover the last
			//	time we drew a line, take that into account when calculating
			//	the offset. leftOverDistance is always < spacing.
			offsetX += stepX * (spacing - leftOverDistance);
			offsetY += stepY * (spacing - leftOverDistance);
			
			leftOverDistance -= spacing;
		} else {
			// The normal case. The offset increment is the normalized vector
			//	times the spacing
			offsetX += stepX * spacing;
			offsetY += stepY * spacing;
		}
		
		// Calculate where to put the current stamp at.
		NSPoint stampAt = NSMakePoint(startPoint.x + offsetX, startPoint.y + offsetY);
		
		// Ka-chunk! Draw the image at the current location
		[self stampMask:mask at: stampAt];
		
		// Remove the distance we just covered
		totalDistance -= spacing;
	}
	
	// Return the distance that we didn't get to cover when drawing the line.
	//	It is going to be less than spacing.
	return totalDistance;	
}

- (void)stampMask:(CGImageRef)mask at:(NSPoint)point
{
	// When we stamp the image, we want the center of the image to be
	//	at the point specified.
	CGContextSaveGState(mBitmapContext);

	// So we can position the image correct, compute where the bottom left
	//	of the image should go, and modify the CTM so that 0, 0 is there.
	CGPoint bottomLeft = CGPointMake( point.x - CGImageGetWidth(mask) * 0.5,
									  point.y - CGImageGetHeight(mask) * 0.5 );
	CGContextTranslateCTM(mBitmapContext, bottomLeft.x, bottomLeft.y);
	
	// Now that it's properly lined up, draw the image
	CGRect maskRect = CGRectMake(0, 0, CGImageGetWidth(mask), CGImageGetHeight(mask));
	CGContextDrawImage(mBitmapContext, maskRect, mask);
	
	CGContextRestoreGState(mBitmapContext);
}

@end
