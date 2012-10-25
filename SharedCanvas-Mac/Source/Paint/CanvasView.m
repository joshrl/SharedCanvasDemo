//
//  CanvasView.m
//  Paint
//


#import "CanvasView.h"

@interface CanvasView()

@end

@implementation CanvasView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self clear];
    }
    return self;
}



- (void) dealloc
{

}

- (void)clear
{
    self.canvas = [[Canvas alloc] initWithSize:[NSScreen mainScreen].frame.size];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
	// Simply ask the canvas to draw into the current context, given the
	//	rectangle specified. A more sophisticated view might draw a border
	//	around the canvas, or a pasteboard in the case that the view was
	//	bigger than the canvas.
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	
	[self.canvas drawRect:rect inContext:context];
}


- (void)brushDown:(Brush *)brush point:(NSPoint )point
{
    [brush brushDownAtPointInWindow:point inView:self onCanvas:self.canvas];

}

- (void)brushDrag:(Brush *)brush point:(NSPoint )point
{
    [brush brushDraggedAtPointInWindow:point inView:self onCanvas:self.canvas];

}

- (void)brushUp:(Brush *)brush point:(NSPoint )point
{
    [brush brushUpAtPointInWindow:point inView:self onCanvas:self.canvas];
}

//- (void)mouseDown:(NSEvent *)theEvent
//{
//	// Simply pass the mouse event to the brush. Also give it the canvas to
//	//	work on, and a reference to ourselves, so it can translate the mouse
//	//	locations.
//	[brush mouseDown:theEvent inView:self onCanvas:self.canvas];
//}
//
//- (void)mouseDragged:(NSEvent *)theEvent
//{
//	// Simply pass the mouse event to the brush. Also give it the canvas to
//	//	work on, and a reference to ourselves, so it can translate the mouse
//	//	locations.	
//	[self.brush mouseDragged:theEvent inView:self onCanvas:self.canvas];
//}
//
//- (void)mouseUp:(NSEvent *)theEvent
//{
//	// Simply pass the mouse event to the brush. Also give it the canvas to
//	//	work on, and a reference to ourselves, so it can translate the mouse
//	//	locations.	
//	[self.brush mouseUp:theEvent inView:self onCanvas:self.canvas];
//}

@end
