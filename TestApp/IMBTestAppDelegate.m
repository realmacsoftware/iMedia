/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2012 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
	Redistributions of source code must retain the original terms stated here,
	including this list of conditions, the disclaimer noted below, and the
	following copyright notice: Copyright (c) 2005-2012 by Karelia Software et al.

	Redistributions in binary form must include, in an end-user-visible manner,
	e.g., About window, Acknowledgments window, or similar, either a) the original
	terms stated here, including this list of conditions, the disclaimer noted
	below, and the aforementioned copyright notice, or b) the aforementioned
	copyright notice and a link to karelia.com/imedia.

	Neither the name of Karelia Software, nor Sandvox, nor the names of
	contributors to iMedia Browser may be used to endorse or promote products
	derived from the Software without prior and express written permission from
	Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
 */


// Author: Peter Baumgartner, Dan Wood, Christoph Priebe, Jörg Jacobsen


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import <iMedia/iMedia.h>
#import "IMBTestAppDelegate.h"
#import "SBUtilities.h"
#import "IMBParserController.h"
#import "IMBImageObjectViewController.h"
#import <iMedia/IMBiPhotoEventObjectViewController.h>
#import <iMedia/IMBFaceObjectViewController.h>
#import <iMedia/IMBOutlineView.h>
#import <iMedia/IMBTableView.h>
#import <iMedia/NSImage+iMedia.h>
#import "IMBTestiPhotoEventBrowserCell.h"
#import "IMBTestFaceBrowserCell.h"
#import "IMBTestFacesBackgroundLayer.h"
#import "IMBAccessRightsController.h"
#import "IMBTableViewAppearance.h"
#import "IMBComboTableViewAppearance.h"


//----------------------------------------------------------------------------------------------------------------------


#pragma mark CONSTANTS

#define LOG_PARSERS 0
#define LOG_CREATE_NODE 0
#define LOG_POPULATE_NODE 0
#define CUSTOM_USER_INTERFACE 0


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

@interface IMBTestAppDelegate ()
- (NSImage*) badgeForObject:(IMBObject*) inObject;
@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

@implementation IMBTestAppDelegate

@synthesize nodeViewController = _nodeViewController;
//@synthesize objectViewController = _objectViewController;
@synthesize usedObjects = _usedObjects;


//----------------------------------------------------------------------------------------------------------------------


+ (void) initialize
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableDictionary *defaultDefaults = [NSMutableDictionary dictionary];
	//NSMutableDictionary *defaultDefaults = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"WebIconDatabaseEnabled"];

	NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults* defaults = [controller defaults];
	
	[defaults registerDefaults:defaultDefaults];
	[controller setInitialValues:defaultDefaults];
	
    NSLog(@"Garbage Collection is %@", [NSGarbageCollector defaultCollector] != nil ? @"ON" : @"OFF");
	
	[pool release];
}


//----------------------------------------------------------------------------------------------------------------------


- (void) awakeFromNib
{
	// NSLog(@"MAC OS X VERSION MIN REQUIRED = %d, MAC OS X VERSION MAX ALLOWED = %d",   MAC_OS_X_VERSION_MIN_REQUIRED, MAC_OS_X_VERSION_MAX_ALLOWED);
	
	[IMBConfig setShowsGroupNodes:YES];
	[IMBConfig setUseGlobalViewType:NO];
    [IMBConfig setClientAppCanHandleSecurityScopedBookmarks:YES];
	
	self.usedObjects = [NSMutableDictionary dictionary];

    NSString* sandboxIndicator = SBIsSandboxed() ? @" (Sandboxed)" : @"";
    
    
    NSString* titleFormat = NSLocalizedStringWithDefaultValue(@"IMBTestAppDelegate.dragWindowTitleFormat", nil,
                                                              [NSBundle mainBundle], @"Drag Media Here%@",
                                                              @"Parameter is either \" (Sandboxed)\" or empty");

    ibDragDestinationWindow.title = [NSString stringWithFormat:titleFormat,sandboxIndicator];
	
	#if CUSTOM_USER_INTERFACE
	
	// Load parsers...
	
	IMBParserController* parserController = [IMBParserController sharedParserController];
	[parserController setDelegate:self];
	[parserController loadParserMessengers];
	
	// Create libraries (singleton per mediaType)...
	
	IMBLibraryController* libraryController = [IMBLibraryController sharedLibraryControllerWithMediaType:kIMBMediaTypeImage];
	[libraryController setDelegate:self];
	
	// Link the user interface (possible multiple instances) to the	singleton library...
	
	self.nodeViewController = [IMBNodeViewController viewControllerForLibraryController:libraryController delegate:self];
	NSView* nodeView = self.nodeViewController.view;
	
    IMBObjectViewController* objectViewController =
    [IMBImageObjectViewController viewControllerForLibraryController:libraryController
                                                            delegate:self];
    self.nodeViewController.standardObjectViewController = objectViewController;
	[self.nodeViewController installObjectViewForNode:nil];
    
    // Customize appearence of outline view
    
    IMBOutlineView* outlineView = self.nodeViewController.nodeOutlineView;
    
    IMBTableViewAppearance* tableViewAppearance =
    [[[IMBTableViewAppearance alloc] initWithView:outlineView] autorelease];
    
    tableViewAppearance.keyWindowHighlightGradient =
    [[[NSGradient alloc] initWithColorsAndLocations:
     [NSColor colorWithDeviceWhite:(float)200/255 alpha:1.0], 0.0,
     [NSColor colorWithDeviceWhite:(float)230/255 alpha:1.0], 1.0, nil] autorelease];
    
    tableViewAppearance.nonKeyWindowHighlightGradient =
    [[[NSGradient alloc] initWithColorsAndLocations:
      [NSColor colorWithDeviceWhite:(float)180/255 alpha:1.0], 0.0,
      [NSColor colorWithDeviceWhite:(float)210/255 alpha:1.0], 1.0, nil] autorelease];
    
    tableViewAppearance.rowTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSColor colorWithDeviceWhite:(float)210/255 alpha:1.0], NSForegroundColorAttributeName,
                                          [NSFont fontWithName:@"Lucida Grande" size:12], NSFontAttributeName,
                                          nil];
    
    tableViewAppearance.rowTextHighlightAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  [NSColor colorWithDeviceWhite:(float)60/255 alpha:1.0], NSForegroundColorAttributeName,
                                                  [NSFont fontWithName:@"Lucida Grande Bold" size:12], NSFontAttributeName,
                                                  nil];
    
    NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(0.0, 0.0)];
    
    tableViewAppearance.sectionHeaderTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSColor colorWithDeviceWhite:(float)150/255 alpha:1.0], NSForegroundColorAttributeName,
                                                   [NSFont fontWithName:@"Lucida Grande Bold" size:11], NSFontAttributeName,
                                                   shadow, NSShadowAttributeName,
                                                   nil];
    
    
    
    // Tell view to use highlight icons as normal icons and vice versa
    
    tableViewAppearance.swapIconAndHighlightIcon = YES;
    
    // Change background color of node view
    
    [outlineView setBackgroundColor:[NSColor colorWithDeviceWhite:(float)90/255 alpha:1.0]];
    
    [outlineView setNeedsDisplay:YES];
    
    // Observe node view controller whenever it sets its object view controller
    // so you can better adapt to your customization needs
    
	[self.nodeViewController addObserver:self forKeyPath:@"objectViewController" options:0 context:NULL];
	
	[nodeView setFrame:[ibWindow.contentView bounds]];
	[ibWindow setContentView:nodeView];
	[ibWindow setContentMinSize:[self.nodeViewController minimumViewSize]];
	
	// Restore window size...
	
	NSString* frame = [IMBConfig prefsValueForKey:@"windowFrame"];
	if (frame) [ibWindow setFrame:NSRectFromString(frame) display:YES animate:NO];
	
	// Load the library...
	
	[libraryController reload];
	[ibWindow makeKeyAndOrderFront:nil];
	
	#else
	
	// Just open the standard iMedia panel...
	
	[self togglePanel:nil];
	
	#endif

}


//----------------------------------------------------------------------------------------------------------------------


- (IBAction) reload:(id)inSender
{
	NSString* mediaType = [[IMBPanelController sharedPanelController] currentMediaType];
	[[IMBLibraryController sharedLibraryControllerWithMediaType:mediaType] reload];
}


//----------------------------------------------------------------------------------------------------------------------


// Toggle panel visibility...

- (IBAction) togglePanel:(id)inSender
{
	if ([IMBPanelController isSharedPanelControllerLoaded])
	{
		IMBPanelController* controller = [IMBPanelController sharedPanelController];
		NSWindow* window = controller.window;
		
		if (window.isVisible)
		{
			[controller hideWindow:inSender];
		}
		else
		{
			[controller showWindow:inSender];
		}
	}
	else
	{
		NSArray* mediaTypes = [NSArray arrayWithObjects:kIMBMediaTypeImage,kIMBMediaTypeAudio,kIMBMediaTypeMovie,kIMBMediaTypeLink,nil];
		IMBPanelController* panelController = [IMBPanelController sharedPanelControllerWithDelegate:self mediaTypes:mediaTypes];
		
		// Set a handle onto the node view controller (need it later for notifying about badge changes)
//		self.nodeViewController = [(IMBObjectViewController*)[[panelController viewControllers] objectAtIndex:0] nodeViewController];
		
		[panelController showWindow:nil];
		[panelController.window makeKeyAndOrderFront:nil];		// Test app, and stand-alone app, would want this to become key.
		
	}
}


//----------------------------------------------------------------------------------------------------------------------


- (IBAction) toggleDragDestinationWindow:(id)inSender
{
	if (ibDragDestinationWindow.isVisible)
	{
		[ibDragDestinationWindow orderOut:inSender];
	}
	else
	{
		[ibDragDestinationWindow makeKeyAndOrderFront:inSender];
	}
}


//----------------------------------------------------------------------------------------------------------------------


// Perform cleanup and save window frame to prefs...

- (void) applicationWillTerminate:(NSNotification*)inNotification
{
	NSString* frame = NSStringFromRect(ibWindow.frame);
	if (frame) [IMBConfig setPrefsValue:frame forKey:@"windowFrame"];
}


// Cleanup...

- (void) dealloc
{
	IMBRelease(_nodeViewController);
//	IMBRelease(_objectViewController);
	[super dealloc];
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 
#pragma mark IMBParserController Delegate


// Make sure that unwanted parser classes aren't even loaded...

- (BOOL) parserController:(IMBParserController*)inController shouldLoadParserMessengerWithIdentifier:(NSString*)inIdentifier
{
	if ([inIdentifier isEqualToString:@"com.karelia.imedia.folder.DesktopPictures"])
	{
		return YES;
	}
    else if ([inIdentifier isEqualToString:@"com.karelia.imedia.folder.UserPictures"])
    {
        return YES;
    }
    else if ([inIdentifier isEqualToString:@"com.karelia.imedia.folder.iChatIcons"])
    {
        return YES;
    }
    else if (IMBRunningOnSnowLeopardOrNewer()) {
        NSSet *unqualifiedParserMessengerIdentifiers =
        [NSSet setWithObjects:
//         @"com.apple.medialibrary.Photos.image",               /* Apple Photos (Apple Media Library) */
//         @"com.apple.medialibrary.iPhoto.image",               /* iPhoto (Apple Media Library) */
//         @"com.apple.medialibrary.iPhoto.movie",               /* iPhoto (Apple Media Library) */
//         @"com.apple.medialibrary.Aperture.image",             /* Aperture (Apple Media Library) */
//         @"com.apple.medialibrary.Aperture.movie",             /* Aperture (Apple Media Library) */
//         @"com.karelia.imedia.iTunes.audio",
//         @"com.karelia.imedia.iTunes.movie",
         @"com.karelia.imedia.iPhoto.image",
         @"com.karelia.imedia.iPhoto.movie",
         @"com.karelia.imedia.Aperture.image",
         @"com.karelia.imedia.Aperture.movie",
         nil];
        if ([unqualifiedParserMessengerIdentifiers containsObject:inIdentifier]) {
            return NO;
        }
    }
	
	return YES;
}


// User this delegate method to configure an IMBParserMessenger before it's being used for the first time...

- (void) parserController:(IMBParserController*)inController didLoadParserMessenger:(IMBParserMessenger*)inParserMessenger;
{

}


// Here custom stuff done in the previous method can be cleaned up again...

- (void) parserController:(IMBParserController*)inController willUnloadParserMessenger:(IMBParserMessenger*)inParserMessenger;
{

}


// Old methods:

/*
- (BOOL) parserController:(IMBParserController*)inController shouldLoadParser:(NSString *)parserClassname forMediaType:(NSString*)inMediaType
{
	BOOL result = YES;
#if LOG_PARSERS
	NSLog(@"%s inParserClass=%@ inMediaType=%@",__FUNCTION__,parserClassname,inMediaType);
#endif
	
	if ([parserClassname isEqualToString:@"IMBImageCaptureParser"])
	{
		return NO;
	}
	
	//	if ([parserClassname isEqualToString:@"IMBFlickrParser"])
	//	{
	//		// Quick check keychain.  Detailed fetching is below in "didLoadParser" though.
	//		SecKeychainItemRef item = nil;
	//		UInt32 stringLength;
	//		char* buffer;
	//		OSStatus err = SecKeychainFindGenericPassword(NULL,10,"flickr_api",0,nil,&stringLength,(void**)&buffer,&item);
	//		if (err == noErr)
	//		{
	//			SecKeychainItemFreeContent(NULL, buffer);
	//		}
	//		result = (item != nil && err == noErr);
	//	}
	return result;
}


- (void) parserController:(IMBParserController*)inController willUnloadParser:(IMBParser*)inParser forMediaType:(NSString*)inMediaType
{
#if LOG_PARSERS
	NSLog(@"%s inParser=%@ inMediaType=%@",__FUNCTION__,NSStringFromClass(inParser.class),inMediaType);
#endif
}
*/

//----------------------------------------------------------------------------------------------------------------------


#pragma mark 
#pragma mark IMBLibraryController Delegate


- (BOOL) libraryController:(IMBLibraryController*)inController shouldCreateNodeWithParserMessenger:(IMBParserMessenger*)inParserMessenger
{
	return YES;
}


- (void) libraryController:(IMBLibraryController*)inController willCreateNodeWithParserMessenger:(IMBParserMessenger*)inParserMessenger
{

}

/**
 How to change the standard (alphabetical) order of nodes to some other order.
 */
- (void)libraryController:(IMBLibraryController *)inController willReplaceNode:(IMBNode *)inOldNode withNode:(IMBNode *)inNewNode
{
    // Helper to remove trailing part of identifier, e.g. "image", "audio, ... for some identifiers to keep map small
    static NSString *(^baseDomainName)(NSString *) = ^NSString *(NSString *identifier)
    {
        NSRange divider = [identifier rangeOfString:@"." options:NSBackwardsSearch];
        
        if (divider.location != NSNotFound) return [identifier substringToIndex:divider.location];
        else return identifier;
    };
    static NSDictionary *topLevelNodeDisplayPriorityMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        topLevelNodeDisplayPriorityMap = [@{
                                           @"com.apple.medialibrary.Photos" :   @(10),
                                           @"com.apple.medialibrary.iPhoto" :   @(20),
                                           @"com.apple.medialibrary.Aperture" : @(30),
                                           @"com.karelia.imedia.Lightroom6" :   @(40),
                                           @"com.karelia.imedia.Lightroom5" :   @(50),
                                           @"com.karelia.imedia.Lightroom4" :   @(60),
                                           @"com.karelia.imedia.Lightroom3" :   @(70),
                                           @"com.karelia.imedia.Lightroom2" :   @(80),
                                           @"com.karelia.imedia.Lightroom1" :   @(90),
                                           } retain];
    });
    if (![inNewNode isTopLevelNode]) return;
    
    NSString *parserMessengerIdentifier = [[inNewNode.parserMessenger class] identifier];
    
    NSNumber *nodeDisplayPriority = topLevelNodeDisplayPriorityMap[parserMessengerIdentifier];
    if (!nodeDisplayPriority) {
        nodeDisplayPriority = topLevelNodeDisplayPriorityMap[baseDomainName(parserMessengerIdentifier)];
    }
    if (nodeDisplayPriority) {
        inNewNode.displayPriority = [nodeDisplayPriority integerValue];
        return;
    }
    inNewNode.displayPriority = 500;
}

- (void) libraryController:(IMBLibraryController*)inController didCreateNode:(IMBNode*)inNode withParserMessenger:(IMBParserMessenger*)inParserMessenger
{

}


- (BOOL) libraryController:(IMBLibraryController*)inController shouldPopulateNode:(IMBNode*)inNode
{
	return YES;
}


- (void) libraryController:(IMBLibraryController*)inController willPopulateNode:(IMBNode*)inNode
{

}


- (void) libraryController:(IMBLibraryController*)inController didPopulateNode:(IMBNode*)inNode
{

}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark IMBNodeViewControllerDelegate

- (NSString *)facebookAppId
{
    // Return a valid Facebook app id here if you want to access Facebook from node view
    return nil;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark IMBObjectViewControllerDelegate


- (Class) imageBrowserCellClassForController:(IMBObjectViewController*)inController
{
	if ([inController isKindOfClass:[IMBiPhotoEventObjectViewController class]])
	{
		return [IMBTestiPhotoEventBrowserCell class];
	}
	if ([inController isKindOfClass:[IMBFaceObjectViewController class]])
	{
		return [IMBTestFaceBrowserCell class];
	}
	return nil;
}


- (CALayer*) imageBrowserBackgroundLayerForController:(IMBObjectViewController*)inController
{
	if ([inController isKindOfClass:[IMBiPhotoEventObjectViewController class]])
	{
		NSRect viewFrame = [[inController iconView] frame];
		NSRect backgroundRect = NSMakeRect(0, 0, viewFrame.size.width, viewFrame.size.height);		
		CALayer *backgroundLayer = [CALayer layer];
		backgroundLayer.frame = *(CGRect*) &backgroundRect;
		
		CGFloat fillComponents[4] = {0.2, 0.2, 0.2, 1.0};
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		CGColorRef color = CGColorCreate(colorSpace, fillComponents);
		[backgroundLayer setBackgroundColor:color];
        CFRelease(colorSpace);
        CFRelease(color);
		
		return backgroundLayer;
	}
	
	if ([inController isKindOfClass:[IMBFaceObjectViewController class]])
	{
		IMBTestFacesBackgroundLayer* backgroundLayer = [[[IMBTestFacesBackgroundLayer alloc] init] autorelease];
		[[inController iconView] setBackgroundLayer:backgroundLayer];
		[backgroundLayer setOwner:[inController iconView]];
		
		return backgroundLayer;
	}
	return nil;
}


- (void) objectViewController:(IMBObjectViewController*)inController didLoadViews:(NSDictionary*)inViews
{
	// Always show icon view when on events node (and hide view selection control)
	
	if ([inController isKindOfClass:[IMBiPhotoEventObjectViewController class]])
	{
		// This makes good sense only if we are not in "use global view type" mode
		
		if (![IMBConfig useGlobalViewType]) {
			// Make sure the object view controller's preferences reflect the view type we want to show
			// (preferences will later be loaded into object)
			
			NSMutableDictionary* preferences = [[[IMBConfig prefsForClass:inController.class] mutableCopy] autorelease];
			[preferences setObject:[NSNumber numberWithUnsignedInteger:0] forKey:@"viewType"];
			[IMBConfig setPrefs:preferences forClass:inController.class];
			
			// Hide the control
			
			NSSegmentedControl* segmentedControl = [inViews objectForKey:IMBObjectViewControllerSegmentedControlKey];
			[segmentedControl setHidden:YES];
		}
	} else if ([inController isKindOfClass:[IMBFaceObjectViewController class]])
	{
		IKImageBrowserView* iconView = [inController iconView];
		
		// Set some title attributes to mimic iPhoto titles for faces
		
		[iconView setValue:[IMBTestFaceBrowserCell titleAttributes] forKey:IKImageBrowserCellsTitleAttributesKey];
	}
    
#if CUSTOM_USER_INTERFACE
    
    IMBObjectViewController* ovc = inController;
    
    // Setup custom appearance on object views
    
    NSGradient* keyWindowHighlightGradient =
    [[[NSGradient alloc] initWithColorsAndLocations:
      [NSColor colorWithDeviceWhite:(float)200/255 alpha:1.0], 0.0,
      [NSColor colorWithDeviceWhite:(float)230/255 alpha:1.0], 1.0, nil] autorelease];
    
    NSGradient* nonKeyWindowHighlightGradient =
    [[[NSGradient alloc] initWithColorsAndLocations:
      [NSColor colorWithDeviceWhite:(float)180/255 alpha:1.0], 0.0,
      [NSColor colorWithDeviceWhite:(float)210/255 alpha:1.0], 1.0, nil] autorelease];
    
    NSDictionary* rowTextAttributes =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSColor colorWithDeviceWhite:(float)240/255 alpha:1.0], NSForegroundColorAttributeName,
     [NSFont fontWithName:@"Lucida Grande" size:12], NSFontAttributeName,
     nil];
    
    NSDictionary* rowTextHighlightAttributes =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSColor colorWithDeviceWhite:(float)60/255 alpha:1.0], NSForegroundColorAttributeName,
     [NSFont fontWithName:@"Lucida Grande Bold" size:12], NSFontAttributeName,
     nil];
    
    NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSDictionary* subRowTextAttributes =
    [NSDictionary dictionaryWithObjectsAndKeys:
     paragraphStyle, NSParagraphStyleAttributeName,
     [NSColor colorWithDeviceWhite:(float)240/255 alpha:0.4], NSForegroundColorAttributeName,
     [NSFont fontWithName:@"Lucida Grande" size:12], NSFontAttributeName,
     nil];
    
    NSDictionary* subRowTextHighlightAttributes =
    [NSDictionary dictionaryWithObjectsAndKeys:
     paragraphStyle, NSParagraphStyleAttributeName,
     [NSColor colorWithDeviceWhite:(float)60/255 alpha:0.4], NSForegroundColorAttributeName,
     [NSFont fontWithName:@"Lucida Grande" size:11], NSFontAttributeName,
     nil];
    
    NSArray* backgroundColors =
    [NSArray arrayWithObjects:
     [NSColor colorWithDeviceWhite:(float)140/255 alpha:1.0],
     [NSColor colorWithDeviceWhite:(float)135/255 alpha:1.0], nil];
    
    void(^setAppearance)(NSView*, Class) = ^(NSView* inView, Class inAppearanceClass) {
        if ([inView isKindOfClass:[IMBTableView class]])
        {
            IMBTableView *tableView = (IMBTableView *)inView;
            
            IMBTableViewAppearance* appearance =
            [[[inAppearanceClass alloc] initWithView:tableView] autorelease];
            
            appearance.keyWindowHighlightGradient = keyWindowHighlightGradient;
            appearance.nonKeyWindowHighlightGradient = nonKeyWindowHighlightGradient;
            appearance.rowTextAttributes = rowTextAttributes;
            appearance.rowTextHighlightAttributes = rowTextHighlightAttributes;
            appearance.backgroundColors = backgroundColors;
            
            if ([appearance isKindOfClass:[IMBComboTableViewAppearance class]]) {
                ((IMBComboTableViewAppearance*)appearance).subRowTextAttributes = subRowTextAttributes;
                ((IMBComboTableViewAppearance*)appearance).subRowTextHighlightAttributes = subRowTextHighlightAttributes;
            }
        }
    };
    setAppearance(ovc.listView, [IMBTableViewAppearance class]);
    setAppearance(ovc.comboView, [IMBComboTableViewAppearance class]);
    
#endif
    
}


- (NSImage*) objectViewController:(IMBObjectViewController*) inController badgeForObject:(IMBObject*) inObject
{
	// Suppress badges on skimmable objects like events or faces
	if ([inController isKindOfClass:[IMBSkimmableObjectViewController class]])
	{
		return NULL;
	}
	
	return [self badgeForObject:inObject];
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark IMBFlickrParser Delegate
/*
- (NSArray*) flickrParserSetupDefaultQueries:(IMBFlickrParser*)inFlickrParser
{
	NSMutableArray* defaultNodes = [NSMutableArray array];
	
	//	tag search for 'macintosh' and 'apple'...
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	//	[dict setObject:@"Tagged 'Macintosh' & 'Apple'" forKey:IMBFlickrNodeProperty_Title];
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeMethod_TagSearch] forKey:IMBFlickrNodeProperty_Method];
	[dict setObject:@"macintosh, apple" forKey:IMBFlickrNodeProperty_Query];
	[defaultNodes addObject:dict];
	
	//	tag search for 'iphone' and 'screenshot'...
	dict = [NSMutableDictionary dictionary];
	//	[dict setObject:@"Tagged 'iPhone' & 'Screenshot'" forKey:IMBFlickrNodeProperty_Title];
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeMethod_TagSearch] forKey:IMBFlickrNodeProperty_Method];
	[dict setObject:@"iphone, screenshot" forKey:IMBFlickrNodeProperty_Query];
	[defaultNodes addObject:dict];
	
	//	text search for 'tree'...
	dict = [NSMutableDictionary dictionary];
	//	[dict setObject:@"Search for 'Tree'" forKey:IMBFlickrNodeProperty_Title];
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeMethod_TextSearch] forKey:IMBFlickrNodeProperty_Method];
	[dict setObject:@"tree" forKey:IMBFlickrNodeProperty_Query];
	[defaultNodes addObject:dict];
	
	return defaultNodes;
}
*/
//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Dragging Delegate


- (void) concludeDragOperationForObjects:(NSArray*)inObjects
{
	for (IMBObject* object in inObjects)
	{
        if (object.persistentResourceIdentifier)
        {
            [self.usedObjects setObject:object forKey:object.persistentResourceIdentifier];
        }
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kIMBObjectBadgesDidChangeNotification object:self];
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Observable framework properties

- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext
{
    if ([inObject isKindOfClass:[IMBNodeViewController class]])
    {
        if ([inKeyPath isEqualToString:@"objectViewController"])
        {
            //NSLog(@"Object view controller: %@ set on node view Controller: %@", [inObject objectViewController], inObject);
            
            /* Add your code here */
        }
    }
    //NSLog(@"Property: %@ changed on object: %@", inKeyPath, inObject);
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Helper

- (NSImage*) badgeForObject:(IMBObject*)inObject
{
	if (inObject.persistentResourceIdentifier && [self.usedObjects valueForKey:inObject.persistentResourceIdentifier])
	{
		return [NSImage imb_imageNamed:@"badge_checkbox.png"];
	} 
	
	return nil;
}

#pragma mark -
#pragma mark Debug Menu Actions

- (IBAction)showParserMessengerIdentifiers:(id)sender
{
    [ibDebugInfoView setString:[[IMBParserController sharedParserController] parserMessengerIdentifiersDescription]];
    [ibDebugInfoWindow setTitle:@"Parser Messenger Identifiers For Registered Parser Messengers"];
    [ibDebugInfoWindow makeKeyAndOrderFront:nil];
}

@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark -
#pragma mark Debugging Convenience

#ifdef DEBUG

/*!	Override debugDescription so it's easier to use the debugger.  Not compiled for non-debug versions.
 */
 
@implementation NSDictionary (OverrideDebug)

- (NSString *)debugDescription
{
	return [self description];
}

@end


@implementation NSArray (OverrideDebug)

- (NSString *)debugDescription
{
	if ([self count] > 20)
	{
		NSArray *subArray = [self subarrayWithRange:NSMakeRange(0,20)];
		return [NSString stringWithFormat:@"%@ [... %lu items]", [subArray description], (unsigned long)[self count]];
	}
	else
	{
		return [self description];
	}
}

@end


@implementation NSSet (OverrideDebug)

- (NSString *)debugDescription
{
	return [self description];
}

@end


@implementation NSData (description)

- (NSString *)description
{
	unsigned char *bytes = (unsigned char *)[self bytes];
	unsigned length = [self length];
	NSMutableString *buf = [NSMutableString stringWithFormat:@"NSData %d bytes:\n", length];
	int i, j;
	
	for ( i = 0 ; i < length ; i += 16 )
	{
		if (i > 1024)		// don't print too much!
		{
			[buf appendString:@"\n...\n"];
			break;
		}
		for ( j = 0 ; j < 16 ; j++ )
		{
			int offset = i+j;
			if (offset < length)
			{
				[buf appendFormat:@"%02X ",bytes[offset]];
			}
			else
			{
				[buf appendFormat:@"   "];
			}
		}
		[buf appendString:@"| "];
		for ( j = 0 ; j < 16 ; j++ )
		{
			int offset = i+j;
			if (offset < length)
			{
				unsigned char theChar = bytes[offset];
				if (theChar < 32 || theChar > 127)
				{
					theChar ='.';
				}
				[buf appendFormat:@"%c", theChar];
			}
		}
		[buf appendString:@"\n"];
	}
	[buf deleteCharactersInRange:NSMakeRange([buf length]-1, 1)];
	return buf;
}

@end

#endif
