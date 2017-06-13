/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2015 by Karelia Software et al.
 
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


//----------------------------------------------------------------------------------------------------------------------


// Author: Pierre Bernard, Peter Baumgartner


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "IMBLightroomParserMessenger.h"
#import "IMBLightroom1Parser.h"
#import "IMBLightroom2Parser.h"
#import "IMBLightroom3Parser.h"
#import "IMBLightroom4Parser.h"
#import "IMBLightroom5Parser.h"
#import "IMBLightroom6Parser.h"
#import "IMBLightroom3VideoParser.h"
#import "IMBLightroom4VideoParser.h"
#import "IMBLightroom5VideoParser.h"
#import "IMBLightroom6VideoParser.h"
#import "IMBParserController.h"
#import "NSFileManager+iMedia.h"
#import "NSDictionary+iMedia.h"
#import "NSImage+iMedia.h"
#import "NSObject+iMedia.h"


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

@implementation IMBLightroomParserMessenger


//----------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		self.mediaSource = nil;	// Will be discovered in XPC service
		self.mediaType = [[self class] mediaType];
		self.isUserAdded = NO;
	}
	
	return self;
}


- (void) dealloc
{
	[super dealloc];
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

// Check if Lightroom is installed. Give preference to the newest version...

+ (NSString*) lightroomPath
{
	NSString* path = nil;
	
	if (path == nil) path = [IMBLightroom6Parser lightroomPath];
	if (path == nil) path = [IMBLightroom5Parser lightroomPath];
	if (path == nil) path = [IMBLightroom4Parser lightroomPath];
	if (path == nil) path = [IMBLightroom3Parser lightroomPath];
	if (path == nil) path = [IMBLightroom2Parser lightroomPath];
	if (path == nil) path = [IMBLightroom1Parser lightroomPath];
	
	return path;
}

+ (BOOL) isInstalled
{
	return [self lightroomPath] != nil;
}


+ (NSString*) xpcServiceIdentifierPostfix
{
	return @"Lightroom";
}


+ (NSString*) identifier
{
	return nil;
}


// Library root is parent directory of catalog file

- (NSURL *)libraryRootURLForMediaSource:(NSURL *)inMediaSource
{
    if (inMediaSource)
    {
        return [inMediaSource URLByDeletingLastPathComponent];
    }
    return [super libraryRootURLForMediaSource:inMediaSource];
}


//----------------------------------------------------------------------------------------------------------------------


// This method is called on the XPC service side. Create a IMBParser instance for each Lightroom library we discover...

- (NSArray*) parserInstancesWithError:(NSError**)outError
{
	Class messengerClass = [self class];
	NSMutableArray *parsers = [messengerClass parsers];
	dispatch_once([messengerClass onceTokenRef],
    ^{
		if ([[self class] isInstalled])
		{
			NSString* mediaType = [self mediaType];
			
			if ([mediaType isEqualTo:kIMBMediaTypeImage])
			{
				[parsers addObjectsFromArray:[IMBLightroom1Parser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom2Parser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom3Parser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom4Parser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom5Parser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom6Parser concreteParserInstancesForMediaType:mediaType]];
			}
			else if ([mediaType isEqualTo:kIMBMediaTypeMovie])
			{
				[parsers addObjectsFromArray:[IMBLightroom3VideoParser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom4VideoParser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom5VideoParser concreteParserInstancesForMediaType:mediaType]];
				[parsers addObjectsFromArray:[IMBLightroom6VideoParser concreteParserInstancesForMediaType:mediaType]];
			}
		}
	});

	return (NSArray*)parsers;
}


//----------------------------------------------------------------------------------------------------------------------


- (NSString*) metadataDescriptionForMetadata:(NSDictionary*)inMetadata
{
	if ([self.mediaType isEqualToString:kIMBMediaTypeImage])
	{
		return [NSImage imb_imageMetadataDescriptionForMetadata:inMetadata];
	}
	else if ([self.mediaType isEqualToString:kIMBMediaTypeMovie])
	{
		return [NSDictionary imb_metadataDescriptionForMovieMetadata:inMetadata];
	}
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the list of parsers this messenger instantiated

+ (NSMutableArray *)parsers
{
	static NSMutableArray *parsers = nil;

	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		parsers = [[NSMutableArray alloc] init];
	});
	return parsers;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the dispatch-once token

+ (dispatch_once_t *)onceTokenRef
{
	static dispatch_once_t onceToken = 0;

	return &onceToken;
}

@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

// Specify parameters for image subclass and register it...
 
@implementation IMBLightroomImageParserMessenger

+ (NSString*) mediaType
{
	return kIMBMediaTypeImage;
}

+ (NSString*) identifier
{
	if ([IMBLightroom6Parser lightroomPath])
	{
		return [IMBLightroom6Parser identifier];
	}
	else if ([IMBLightroom5Parser lightroomPath])
	{
		return [IMBLightroom5Parser identifier];
	}
	else if ([IMBLightroom4Parser lightroomPath])
	{
		return [IMBLightroom4Parser identifier];
	}
	else if ([IMBLightroom3Parser lightroomPath])
	{
		return [IMBLightroom3Parser identifier];
	}
	else if ([IMBLightroom2Parser lightroomPath])
	{
		return [IMBLightroom2Parser identifier];
	}
	else if ([IMBLightroom1Parser lightroomPath])
	{
		return [IMBLightroom1Parser identifier];
	}

	return nil;
}

+ (NSString*) parserClassName
{
	if ([IMBLightroom6Parser lightroomPath])
	{
		return @"IMBLightroom6Parser";
	}
	else if ([IMBLightroom5Parser lightroomPath])
	{
		return @"IMBLightroom5Parser";
	}
	else if ([IMBLightroom4Parser lightroomPath])
	{
		return @"IMBLightroom4Parser";
	}
	else if ([IMBLightroom3Parser lightroomPath])
	{
		return @"IMBLightroom3Parser";
	}
	else if ([IMBLightroom2Parser lightroomPath])
	{
		return @"IMBLightroom2Parser";
	}
	else if ([IMBLightroom1Parser lightroomPath])
	{
		return @"IMBLightroom1Parser";
	}
	
	return nil;
}
					
+ (void) load
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[IMBParserController registerParserMessengerClass:self forMediaType:[self mediaType]];
	[pool drain];
}

//----------------------------------------------------------------------------------------------------------------------
// Returns the list of parsers this messenger instantiated

+ (NSMutableArray *)parsers
{
	static NSMutableArray *parsers = nil;

	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		parsers = [[NSMutableArray alloc] init];
	});
	return parsers;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the dispatch-once token

+ (dispatch_once_t *)onceTokenRef
{
	static dispatch_once_t onceToken = 0;

	return &onceToken;
}

@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark 

// Specify parameters for movie subclass and register it...
 
@implementation IMBLightroomMovieParserMessenger

+ (NSString*) mediaType
{
	return kIMBMediaTypeMovie;
}

+ (NSString*) identifier
{
	if ([IMBLightroom6VideoParser lightroomPath])
	{
		return [IMBLightroom6VideoParser identifier];
	}
	else if ([IMBLightroom5VideoParser lightroomPath])
	{
		return [IMBLightroom5VideoParser identifier];
	}
	else if ([IMBLightroom4VideoParser lightroomPath])
	{
		return [IMBLightroom4Parser identifier];
	}
	else if ([IMBLightroom3VideoParser lightroomPath])
	{
		return [IMBLightroom3VideoParser identifier];
	}

	return nil;
}

+ (NSString*) parserClassName
{
	if ([IMBLightroom6Parser lightroomPath])
	{
		return @"IMBLightroom6VideoParser";
	}
	else if ([IMBLightroom5Parser lightroomPath])
	{
		return @"IMBLightroom5VideoParser";
	}
	else if ([IMBLightroom4Parser lightroomPath])
	{
		return @"IMBLightroom4VideoParser";
	}
	else if ([IMBLightroom3Parser lightroomPath])
	{
		return @"IMBLightroom3VideoParser";
	}
	
	return nil;
}
						
+ (void) load
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[IMBParserController registerParserMessengerClass:self forMediaType:[self mediaType]];
	[pool drain];
}

//----------------------------------------------------------------------------------------------------------------------
// Returns the list of parsers this messenger instantiated

+ (NSMutableArray *)parsers
{
	static NSMutableArray *parsers = nil;

	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		parsers = [[NSMutableArray alloc] init];
	});
	return parsers;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the dispatch-once token

+ (dispatch_once_t *)onceTokenRef
{
	static dispatch_once_t onceToken = 0;

	return &onceToken;
}

@end


//----------------------------------------------------------------------------------------------------------------------

