//
//  Brush.h
//  Paint
//


#import <Cocoa/Cocoa.h>

@class Canvas;

@interface Brush : NSObject {
	// Information about the brush that's always used
	float				mRadius;
	CGMutablePathRef	mShape;
	CGColorRef			mColor;
	float				mSoftness; // 0.0 - 1.0, 0.0 being hard, 1.0 be all soft
	BOOL				mHard; // should have a hard edge?
	
	// Cached information that's only used when actually tracking/drawing
	CGImageRef			mMask;
	NSPoint				mLastPoint;
	float				mLeftOverDistance;
}
- (id) initWithBrushSize:(float)diameter
                softness:(float)softness
                   alpha:(float)alpha
                   color:(NSColor *)color;

- (void) brushDownAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas;
- (void) brushDraggedAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas;
- (void) brushUpAtPointInWindow:(NSPoint)p inView:(NSView *)view onCanvas:(Canvas *)canvas;

- (void) mouseDown:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas;
- (void) mouseDragged:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas;
- (void) mouseUp:(NSEvent *)theEvent inView:(NSView *)view onCanvas:(Canvas *)canvas;

@end
