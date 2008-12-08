// A command-line tool to start a drag session for the filename provided
// Ciarán Walsh, 2008
// Visit http://github.com/ciaran/drag for the latest version
// 
// Compile with:
//   g++ drag.mm -framework Cocoa -o drag
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

static BOOL exitRunLoop = NO;

@interface DragSource : NSObject
@end

@implementation DragSource
- (void)draggedImage:(NSImage*)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)aDragOperation
{
	exitRunLoop = YES;
}
@end

BOOL mouse_button_is_down ()
{
	return CGEventSourceButtonState(kCGEventSourceStateHIDSystemState, kCGMouseButtonLeft);
}

int main (int argc, char const* argv[])
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];

	NSString* path = nil;
	if(argc == 2)
		path = [[NSString stringWithUTF8String:argv[1]] stringByExpandingTildeInPath];

	if(!path || [path length] == 0)
	{
		fprintf(stderr, "No path given.\n");
		exit(1);
	}

	if(![path isAbsolutePath])
		path = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:path];

	if(![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		fprintf(stderr, "The file “%s” does not exist.\n", [path UTF8String]);
		exit(1);
	}

	printf("Dragging %s\n", [path UTF8String]);

	NSApplicationLoad();

	if(!mouse_button_is_down())
	{
		fprintf(stderr, "Press the left mouse button to start the drag session.\n");
		while(!mouse_button_is_down()) sleep(0);
	}

	NSWindow* window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                                   styleMask:NSTitledWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO] autorelease];

	NSPasteboard* pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
	[pboard setPropertyList:[NSArray arrayWithObject:path] forType:NSFilenamesPboardType];
	[window dragImage:[[NSWorkspace sharedWorkspace] iconForFile:path]
                  at:NSMakePoint(0, 0)
              offset:NSMakeSize(0, 30)
               event:nil
          pasteboard:pboard
              source:[[DragSource new] autorelease]
           slideBack:NO];

	while(!exitRunLoop)
		[NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];

	[pool release];
}
