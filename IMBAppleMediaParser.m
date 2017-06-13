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


// Author: Jörg Jacobsen


//----------------------------------------------------------------------------------------------------------------------

#pragma mark HEADERS

#import "IMBAppleMediaParser+iMediaPrivate.h"
#import "NSWorkspace+iMedia.h"
#import "NSFileManager+iMedia.h"
#import "IMBNode.h"
#import "IMBFaceNodeObject.h"
//#import "IMBiPhotoEventObjectViewController.h"
//#import "IMBFaceObjectViewController.h"
#import "IMBImageObjectViewController.h"
#import "NSImage+iMedia.h"
#import "NSString+iMedia.h"


//----------------------------------------------------------------------------------------------------------------------

#pragma mark CONSTANTS

// node object types of interest for skimming

NSString* const kIMBiPhotoNodeObjectTypeEvent = @"events";
NSString* const kIMBiPhotoNodeObjectTypeFace  = @"faces";


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -

@interface IMBAppleMediaParser ()

- (NSString*) thumbnailPathForImageKey:(NSString*)inImageKey;
- (NSString*) imagePathForFaceIndex:(NSNumber*)inFaceIndex inImageWithKey:(NSString*)inImageKey;
- (BOOL) supportsPhotoStreamFeatureInVersion:(NSString *)inVersion;
- (NSString *) rootNodeIdentifier;

@property (retain) NSDictionary* atomic_plist;
@property (retain,readwrite) NSDate* modificationDate;

@end


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -

@implementation IMBAppleMediaParser

@synthesize appPath = _appPath;
@synthesize atomic_plist = _plist;
@synthesize modificationDate = _modificationDate;
@synthesize shouldDisplayLibraryName = _shouldDisplayLibraryName;


//----------------------------------------------------------------------------------------------------------------------


- (void) dealloc
{
	IMBRelease(_appPath);
	IMBRelease(_plist);
	IMBRelease(_modificationDate);
	[super dealloc];
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Parsing

//----------------------------------------------------------------------------------------------------------------------
// iPhoto and Aperture do not include events nor faces in the album list. To let events or faces also be shown
// in the browser we let events (aka rolls) and faces pose as albums in the album list.

- (void) addSpecialAlbumsToAlbumsInLibrary:(NSMutableDictionary*)inLibraryDict
{	
	NSArray* oldAlbumList = [inLibraryDict objectForKey:@"List of Albums"];
	
    if (oldAlbumList != nil && [oldAlbumList count]>0)
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
        // To insert new albums like events and faces into the album list we have to re-create it mutable style
        NSMutableArray *newAlbumList = [NSMutableArray arrayWithArray:oldAlbumList];
        
		NSUInteger insertionIndex = [self indexOfAllPhotosAlbumInAlbumList:oldAlbumList];
        NSDictionary *photosDict = nil;
        NSDictionary *eventsDict = nil;
		
        // Starting Aperture 3.3 there is no "Photos" album in ApertureData.xml anymore, so we must reconstruct it ourselves
        
        if (insertionIndex == NSNotFound)
        {
            // Photos album right after Projects in Aperture (Projects synonym to Events)
            // Photos album in iPhoto should be already there
            
            insertionIndex = [self indexOfEventsAlbumInAlbumList:oldAlbumList];
            
            if (insertionIndex != NSNotFound &&
                (eventsDict = [oldAlbumList objectAtIndex:insertionIndex]))
            {
				NSNumber *allPhotosId = [NSNumber numberWithUnsignedInt:ALL_PHOTOS_NODE_ID];
				NSString *allPhotosName = [self localizedNameForAlbumName:@"Photos"];
                NSDictionary* allPhotos = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           allPhotosId,   @"AlbumId",
                                           allPhotosName, @"AlbumName",
                                           @"94",  @"Album Type",
                                           [eventsDict objectForKey:@"Parent"], @"Parent", nil];
				
                // events album right before photos album
                
				[newAlbumList insertObject:allPhotos atIndex:insertionIndex];
				IMBRelease(allPhotos);
                insertionIndex++;
            }
        }
        
		if (insertionIndex != NSNotFound &&
            (photosDict = [oldAlbumList objectAtIndex:insertionIndex]))
		{
            // Events
			
			if ([inLibraryDict objectForKey:@"List of Rolls"])
			{
				NSNumber *eventsId = [NSNumber numberWithUnsignedInt:EVENTS_NODE_ID];
				NSString *eventsName = NSLocalizedStringWithDefaultValue(@"IMB.iPhotoParser.events", nil, IMBBundle(), @"Events", @"Events node shown in iPhoto library");
				
				NSDictionary* events = [[NSDictionary alloc] initWithObjectsAndKeys:
										eventsId,   @"AlbumId",
										eventsName, @"AlbumName",
										@"Events",  @"Album Type",
										[photosDict objectForKey:@"Parent"], @"Parent", nil];
				
                // events album right before photos album
                
				[newAlbumList insertObject:events atIndex:insertionIndex];
				IMBRelease(events);
                insertionIndex++;
			}
			
			// Faces album right after photos album
			
			if ([inLibraryDict objectForKey:@"List of Faces"])
			{
				NSNumber *facesId = [NSNumber numberWithUnsignedInt:FACES_NODE_ID];
				NSString *facesName = NSLocalizedStringWithDefaultValue(@"IMB.iPhotoParser.faces", nil, IMBBundle(), @"Faces", @"Faces node shown in iPhoto library");
				
				NSDictionary* faces = [[NSDictionary alloc] initWithObjectsAndKeys:
									   facesId,   @"AlbumId",
									   facesName, @"AlbumName",
									   @"Faces",  @"Album Type",
									   [photosDict objectForKey:@"Parent"], @"Parent", nil];
				
				[newAlbumList insertObject:faces atIndex:insertionIndex + 1];
				IMBRelease(faces);
			}
		}
			
        // Photo Stream album right before Flagged album
        
        insertionIndex = [self indexOfFlaggedAlbumInAlbumList:newAlbumList];
        if ([self supportsPhotoStreamFeatureInVersion:[inLibraryDict objectForKey:@"Application Version"]] &&
            insertionIndex != NSNotFound)
        {
            NSNumber *albumId = [NSNumber numberWithUnsignedInt:PHOTO_STREAM_NODE_ID];
            NSString *albumName = NSLocalizedStringWithDefaultValue(@"IMB.iPhotoParser.photostream", nil, IMBBundle(), @"Photo Stream", @"Photo Stream node shown in iPhoto library");
            
            NSDictionary* album = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   albumId,   @"AlbumId",
                                   albumName, @"AlbumName",
                                   @"Photo Stream",  @"Album Type",
                                   [photosDict objectForKey:@"Parent"], @"Parent", nil];
            
            [newAlbumList insertObject:album atIndex:insertionIndex];
            IMBRelease(album);
        }
        
        // Replace the old albums array.
        
        [inLibraryDict setValue:newAlbumList forKey:@"List of Albums"];
		[pool drain];
	}
}


//----------------------------------------------------------------------------------------------------------------------
// Load the XML file into a plist lazily (on demand). If we notice that an existing cached plist is out-of-date 
// we get rid of it and load it anew...


- (NSDictionary*) plist
{
	NSDictionary* result = nil;
	NSError* error = nil;
	NSString* path = [self.mediaSource path];
	
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSDictionary* metadata = [fileManager attributesOfItemAtPath:path error:&error];
    [fileManager release];
    
//    NSLog(@"%@ metadata:\n%@", path, metadata);
    
    if (metadata)
    {
		NSDate* modificationDate = [metadata objectForKey:NSFileModificationDate];
		
		@synchronized(self)
		{
			if ([self.modificationDate compare:modificationDate] == NSOrderedAscending)
			{
				self.atomic_plist = nil;
			}
			
			if (_plist == nil)
			{
				// Since we want to add events and faces to the list of albums we will need
				// to modify the album data dictionary (see further down below)
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
				
				// WORKAROUND
				if (dict == nil || 0 == dict.count)	// unable to read. possibly due to unencoded '&'.  rdar://7469235
				{
					NSData *data = [NSData dataWithContentsOfFile:path];
					if (data)
					{
						NSString *eString = nil;
						NSError *e = nil;
						@try
						{
							NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data
																				options:NSXMLDocumentTidyXML error:&e];
							dict = [NSPropertyListSerialization
									propertyListFromData:[xmlDoc XMLData]
									mutabilityOption:0					// Apple doc: The opt parameter is currently unused and should be set to 0.
									format:NULL errorDescription:&eString];
							[xmlDoc release];
							
							// the assignment to 'dict' in the code above yields
							// a mutable dictionary as this code snippet would reveal:
							// Class dictClass = [dict classForCoder];
							// NSLog(@"Dictionary class: %@", [dictClass description]);
						}
						@catch(NSException *e)
						{
							NSLog(@"%s %@", __FUNCTION__, e);
						}
						// When we start targetting 10.6, we should use propertyListWithData:options:format:error:
					}
				}			
				
				//	If there is an AlbumData.xml file, there should be something inside!
				
				if (dict == nil || 0 == dict.count)
				{
					NSLog (@"The iPhoto or Aperture XML file seems to be empty. This is an unhealthy condition!");
				} else {
                    // Since this parser confines itself to deal with the "List of Albums" only
                    // we add an events node to the album list to incorporate events in the browser.
                    // This is why we need a mutable library dictionary.
                    
					[self addSpecialAlbumsToAlbumsInLibrary:dict];
                }
				
				self.atomic_plist = dict;
				self.modificationDate = modificationDate;
			}
			
			result = self.atomic_plist;
		}
	}
	
	return result;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark -
#pragma mark IMBParserProtocol

//----------------------------------------------------------------------------------------------------------------------
//

- (IMBNode*) unpopulatedTopLevelNode:(NSError**)outError
{
	NSImage* icon = [[NSWorkspace imb_threadSafeWorkspace] iconForFile:self.appPath];
	[icon setSize:NSMakeSize(16.0,16.0)];
    
	IMBNode* node = [[[IMBNode alloc] initWithParser:self topLevel:YES] autorelease];

    
//    NSLog(@"Node %@ is %@accessible", node, node.isAccessible ? @"" : @"NOT ");
    
	node.icon = icon;
	node.name = [[self class] libraryName];
	node.identifier = [self rootNodeIdentifier];
	node.groupType = kIMBGroupTypeLibrary;
	node.isLeafNode = NO;
	
	if (node.isTopLevelNode)
	{
		if (self.shouldDisplayLibraryName)
        {
            NSString* path = (NSString*)[node.mediaSource path];
            NSString* libraryName = [[[path stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension];
            node.name = [NSString stringWithFormat:@"%@ (%@)",node.name, libraryName];
        } else {
            node.name = [NSString stringWithFormat:@"%@",node.name];
        }
	}
	
	// Enable FSEvents based file watching for root nodes...
	
	node.watcherType = kIMBWatcherTypeFSEvent;
    
	NSURL* url = self.mediaSource;
	NSString* path = [[url path] stringByDeletingLastPathComponent];
	node.watchedPath = path;
	
	// JUST TEMP: remove these 2 lines later...
	
    //	NSDictionary* plist = [NSDictionary dictionaryWithContentsOfURL:self.mediaSource];
    //	node.attributes = plist;
	
	return node;
}


//----------------------------------------------------------------------------------------------------------------------
//

- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
	if (outError) *outError = nil;
    
	NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithDictionary:inObject.preliminaryMetadata];
	
	// Do not load (key) image specific metadata for node objects
	// because it doesn't represent the nature of the object well enough.
	
	if (![inObject isKindOfClass:[IMBNodeObject class]])
	{
		[metadata addEntriesFromDictionary:[NSImage imb_metadataFromImageAtURL:inObject.URL checkSpotlightComments:NO]];
	}
    
// JJ TODO: How about keywords? Only for iPhoto or also for Aperture?
    
    return metadata;
}


//----------------------------------------------------------------------------------------------------------------------
// Since we know that we have local files we can use the helper method supplied by the base class...

- (NSData*) bookmarkForObject:(IMBObject*)inObject error:(NSError**)outError
{
	return [self bookmarkForLocalFileObject:inObject error:outError];
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark -
#pragma mark IMBSkimmableObjectViewControllerDelegate

- (NSUInteger) childrenCountOfNodeObject:(IMBNodeObject*)inNodeObject userInfo:(NSDictionary*)inUserInfo
{
//	return [[inNodeObject.preliminaryMetadata objectForKey:@"PhotoCount"] integerValue];
	return [[inNodeObject.preliminaryMetadata objectForKey:@"KeyList"] count];	// More reliable for Aperture! Avoids out-of-bounds exceptions.
}


- (NSString*) imagePathForChildOfNodeObject:(IMBNodeObject*)inNodeObject atIndex:(NSUInteger)inIndex userInfo:(NSDictionary*)inUserInfo
{
	NSString* imageKey = [[inNodeObject.preliminaryMetadata objectForKey:@"KeyList"] objectAtIndex:inIndex];
	
	// Faces
	if ([[inUserInfo objectForKey:@"nodeObjectType"] isEqualToString:kIMBiPhotoNodeObjectTypeFace])
	{
		// Get the metadata of the nth image in which this face occurs 
		NSDictionary* imageFaceMetadata = [[[inNodeObject preliminaryMetadata] objectForKey:@"ImageFaceMetadataList"] objectAtIndex:inIndex];
		
		// What is the number of this face inside of this image?
		NSNumber* faceIndex = [imageFaceMetadata objectForKey:@"face index"];
		
		// A clipped image of this face in this image is stored in the filesystem
		NSString* imagePath = [self imagePathForFaceIndex:faceIndex inImageWithKey:imageKey];
		
		//NSLog(@"Skimming controller asked delegate for image path and receives: %@", imagePath);
		
		return imagePath;
	}
	
	// Events
	return [self thumbnailPathForImageKey:imageKey];
}


- (NSString*) imagePathForKeyChildOfNodeObject:(IMBNodeObject*)inNodeObject userInfo:(NSDictionary*)inUserInfo
{
	NSString* imageKey = [inNodeObject.preliminaryMetadata objectForKey:@"KeyPhotoKey"];
	
	// Faces
	if ([[inUserInfo objectForKey:@"nodeObjectType"] isEqualToString:kIMBiPhotoNodeObjectTypeFace])
	{
		// Get this face's index inside of this image
		NSNumber* faceIndex = [[inNodeObject preliminaryMetadata] objectForKey:@"key image face index"];
		
		// Get the path to this face's occurence
		NSString* imagePath = [self imagePathForFaceIndex:faceIndex inImageWithKey:imageKey];
		
		return imagePath;
	}
	
	// Events
	return [self thumbnailPathForImageKey:imageKey];
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark To be subclassed


//----------------------------------------------------------------------------------------------------------------------
// Returns name of library. Must be subclassed.

+ (NSString*) libraryName
{
    NSString *errMsg = [NSString stringWithFormat:@"%s: Please use a custom subclass of %@...",__FUNCTION__, [self className]];
	NSLog(@"%@", errMsg);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:errMsg userInfo:nil] raise];
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the identifier of the root node. Must be subclassed.

- (NSString*) rootNodeIdentifier
{
    NSString *errMsg = [NSString stringWithFormat:@"%s: Please use a custom subclass of %@...",__FUNCTION__, [self className]];
	NSLog(@"%@", errMsg);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:errMsg userInfo:nil] raise];
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// Create an identifier from the provided id and id space. An example is "IMBiPhotoParser://FaceId/17"...

- (NSString*) identifierForId:(NSNumber*) inId inSpace:(NSString*) inIdSpace
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// returns whether this album type should be used. Must be subclassed.

- (BOOL) shouldUseAlbumType:(NSString*)inAlbumType
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inAlbumDict should be used. Must be subclassed.

- (BOOL) shouldUseAlbum:(NSDictionary*)inAlbumDict images:(NSDictionary*)inImages
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns a dictionary that contains the "true" KeyList, KeyPhotoKey and PhotoCount values for the provided node.
// (The values provided by the according dictionary in .plist are mostly wrong because we separate node children by
// media types 'Image' and 'Movie' into different views.) Must be subclassed.

- (NSDictionary*) childrenInfoForNode:(NSDictionary*)inNodeDict images:(NSDictionary*)inImages
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns an icon for an album of this type. Must be subclassed.

- (NSImage*) iconForAlbumType:(NSString*)inType highlight:(BOOL)inHighlight
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inAlbumDict is the "Photos" album. Must be subclassed.

- (BOOL) isAllPhotosAlbum:(NSDictionary*)inAlbumDict
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inAlbumDict is the "Events" (aka "Projects") album. Must be subclassed.

- (BOOL) isEventsAlbum:(NSDictionary*)inAlbumDict
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inAlbumDict is the "Flagged" album. Must be subclassed.

- (BOOL) isFlaggedAlbum:(NSDictionary*)inAlbumDict
{
	NSLog(@"%s Please use a custom subclass of IMBAppleMediaParser...",__FUNCTION__);
	[[NSException exceptionWithName:@"IMBProgrammerError" reason:@"Please use a custom subclass of IMBAppleMediaParser" userInfo:nil] raise];
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether the parser supports Apple's Photo Stream feature
// (which is usually dependent on the data delivered through AlbumData.xml or ApertureData.xml respectively)

- (BOOL) supportsPhotoStreamFeatureInVersion:(NSString *)inVersion
{
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Image location

- (id)thumbnailForObject:(IMBObject *)inObject error:(NSError **)outError
{
    // imageLocation of a skimmable node object might be out of sync with its current skimming index
    // (the image location for a skimming index must only be set where the parser is available)
    
    if ([inObject isKindOfClass:NSClassFromString(@"IMBSkimmableObject")])
    {
        IMBSkimmableObject *skimmableObject = (IMBSkimmableObject *)inObject;
        
        skimmableObject.imageLocation = [skimmableObject imageLocationForCurrentSkimmingIndex];
        if (!skimmableObject.imageLocation) {
            return nil;
        }
    }
    
    // IKImageBrowser can also deal with NSData type (IKImageBrowserNSDataRepresentationType)
    
	if (inObject.imageLocation)
	{
		NSURL* url = (NSURL*)inObject.imageLocation;
		if ([inObject.imageRepresentationType isEqualToString:IKImageBrowserCGImageRepresentationType])
        {
            return (id)[self thumbnailFromLocalImageFileForObject:inObject error:outError];
        } else {
            inObject.imageRepresentationType = IKImageBrowserNSDataRepresentationType;
            NSData* data = [NSData dataWithContentsOfURL:url];
            return data;
        }
	}
	else
	{
        inObject.imageRepresentationType = IKImageBrowserCGImageRepresentationType;
		return (id)[self thumbnailFromLocalImageFileForObject:inObject error:outError];
	}
}


//----------------------------------------------------------------------------------------------------------------------
// The image location represents an image path to the image to be used for display inside of the browser (a preview of
// of the original image). By default we use the path to the image's thumbnail (key: "ThumbPath").
// Subclass for distinct behavior.

- (NSString*) imageLocationForObject:(NSDictionary*)inObjectDict
{
	return [inObjectDict objectForKey:@"ThumbPath"];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the image location for the image represented by inImageKey in the master image list (aka dictionary)

- (NSString*) thumbnailPathForImageKey:(NSString*)inImageKey
{
    NSString* imagePath = nil;
    
	NSDictionary* images = [[self plist] objectForKey:@"Master Image List"];
	NSDictionary* imageDict = [images objectForKey:inImageKey];
    
    if (imageDict) {
        imagePath = [self imageLocationForObject:imageDict];
    }
    if (!imagePath) {
        NSBundle* bundle = [NSBundle bundleForClass:[self class]];
        imagePath = [bundle pathForResource:@"missing-thumbnail" ofType:@"jpg"];
    }
	return imagePath; 
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the image location for the clipped face in the image represented by inImageKey in the master image list
// (aka dictionary)

- (NSString*) imagePathForFaceIndex:(NSNumber*)inFaceIndex inImageWithKey:(NSString*)inImageKey
{
	NSString* imagePath = [self thumbnailPathForImageKey:inImageKey];

	if (imagePath) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *facePath = [NSString stringWithFormat:@"%@_face%@.%@",
							  [imagePath stringByDeletingPathExtension],
							  inFaceIndex,
							  [imagePath pathExtension]];

		if ([fileManager fileExistsAtPath:facePath]) {
			return facePath;
		}
		else if ([fileManager fileExistsAtPath:imagePath]) {
			return imagePath;
		}
	}

	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSString* path = [bundle pathForResource:@"missing-thumbnail" ofType:@"jpg"];
	return path;
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Subnode creation and node population

//----------------------------------------------------------------------------------------------------------------------
// Returns array of all face dictionaries (sorted by name). These are also enriched by several keys:
// ImageFaceMetadataList: list of meta info of face occurences in images (sorted by date)
// KeyPhotoKey:           key of key image ('KeyPhotoKey' is an event-compatible key)
// KeyList:               list of all images in which a face occurs (sorted by date)

- (NSArray*) faces:(NSDictionary*)inFaces collectedFromImages:(NSDictionary*)inImages
{
	// Need the enriched copy mutable style
	NSMutableDictionary* facesDict = [NSMutableDictionary dictionaryWithDictionary:inFaces];
	
	// Collect all occurences faces. We iterate over master images because only there AlbumData.xml
	// stores occurences of faces.
	
	NSArray* facesOnImage = nil;
	NSDictionary* imageDict = nil;
	NSMutableDictionary* faceDict = nil;	// Will need to add keys like "KeyList" to dictionary
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	for (NSString* imageDictKey in [inImages keyEnumerator])
	{
		imageDict = [inImages objectForKey:imageDictKey];
		
		// Get all known faces that appear on this image
		facesOnImage = [imageDict objectForKey:@"Faces"];
		
		NSString* imageFaceKey = nil;
		NSMutableArray* imageFaceMetadataList = nil;
		NSDictionary* imageFaceMetadata = nil;
		for (NSDictionary* imageFaceDict in facesOnImage)
		{
			// Get face dictionary for given face key.
			// Face dictionary will be the basis of our subnode to be created.
			
			imageFaceKey = [imageFaceDict objectForKey:@"face key"];
			faceDict = [facesDict objectForKey:imageFaceKey];
			
			// It might well be that found face in image is now longer known...
			if (faceDict)
			{
				// Coming here we found a face on an image and this face is known.
				// Now add some key/value pairs to face dictionary
				
				// First convert to a mutable dictionary to be able to add the extra pairs
				faceDict = [NSMutableDictionary dictionaryWithDictionary:faceDict];
				[facesDict setObject:faceDict forKey:imageFaceKey];
				
                // Provide key image key under event-compatible key "KeyPhotoKey" once current image matches.
                // NOTE: iPhoto 9.4 changed the value stored under "key image" from image key to image GUID.
                
                NSString* keyImage = [faceDict objectForKey:@"key image"];
                NSString* imageGUID = [imageDict objectForKey:@"GUID"];
                
                if ((imageGUID  && [imageGUID isEqualToString:keyImage]) ||     // Should be YES once for >= iPhoto 9.4
                    [imageDictKey isEqualToString:keyImage])                    // Should be YES once for < iPhoto 9.4
                {
                    [faceDict setObject:imageDictKey forKey:@"KeyPhotoKey"];
                }
                
				// Add image face meta data to this face (need this later)
				// (Create meta data list when first occurence of face in some image is detected)
				
				imageFaceMetadataList = [faceDict objectForKey:@"ImageFaceMetadataList"];
				if (!imageFaceMetadataList)
				{
					imageFaceMetadataList = [NSMutableArray array];
					[faceDict setObject:imageFaceMetadataList forKey:@"ImageFaceMetadataList"];
				}
                NSNumber *faceIndex = [imageFaceDict objectForKey:@"face index"];
                NSString *path = [self imagePathForFaceIndex:faceIndex inImageWithKey:imageDictKey];
				imageFaceMetadata = [NSDictionary dictionaryWithObjectsAndKeys:
									 imageDictKey, @"image key",
									 faceIndex, @"face index",
									 [imageDict objectForKey:@"DateAsTimerInterval"], @"DateAsTimerInterval",
                                     path, @"path",
                                     nil];
				
				[imageFaceMetadataList addObject:imageFaceMetadata];
				
			} else {
				// We found a face in a master image but that face is not associated
				// with a known face anymore. Just skip this one.
				
				//NSLog(@"Found unknown face with ID %@ in image %@", faceKey, imageDictKey);
			}
		}
	}
	
	// For each face dictionary sort associated images by date (this is how iPhoto displays them)
	
	NSSortDescriptor* dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"DateAsTimerInterval" ascending:YES];
	NSArray* sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	[dateDescriptor release];
	
	NSArray* imageFaceMetadataList = nil;
	for (NSString* faceKey in [facesDict keyEnumerator])
	{
		faceDict = [facesDict objectForKey:faceKey];
		
		// Sort images related to face by date
		
		imageFaceMetadataList = [faceDict objectForKey:@"ImageFaceMetadataList"];
		if (imageFaceMetadataList)
		{
			imageFaceMetadataList = [imageFaceMetadataList sortedArrayUsingDescriptors:sortDescriptors];
		} else {
			// Obviously a metadata list has yet not been created for this face.
			// Given the code further above this really means that this face does not appear
			// on any image. This should probably not be but there were crash logs indicating just this.
			// Create an empty metadata list to avoid crash.
			imageFaceMetadataList = [NSArray array];
		}
		[faceDict setObject:imageFaceMetadataList forKey:@"ImageFaceMetadataList"]; // JJ/2012-09-21: again?????
		
        // Also store a sorted key list in face dictionary
		[faceDict setObject:[imageFaceMetadataList valueForKey:@"image key"] forKey:@"KeyList"];
	}
	
	[pool drain];
	
	// Sort faces dictionary by names (this is how iPhoto displays faces)
	
	NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	sortDescriptors = [NSArray arrayWithObject:nameDescriptor];
	[nameDescriptor release];
	
	NSArray* sortedFaces = [[facesDict allValues] sortedArrayUsingDescriptors:sortDescriptors];
	
	return sortedFaces;
}


//----------------------------------------------------------------------------------------------------------------------
// Populate faces node and create corresponding subnodes that each represent a single face

- (void) populateFacesNode:(IMBNode*)inNode 
				 withFaces:(NSDictionary*)inFaces
					images:(NSDictionary*)inImages
{

	// Pull all information on faces from faces dictionary and face occurences in images
	// into a faces array (sorted by name)...
	
	NSArray* sortedFaces = [self faces:inFaces collectedFromImages:inImages];
	
	// Create the subNodes array on demand - even if turns out to be empty after exiting this method, 
	// because without creating an array we would cause an endless loop...
    
	NSMutableArray* subnodes = [inNode mutableArrayForPopulatingSubnodes];
	
	// Create the objects array on demand  - even if turns out to be empty after exiting this method, because
	// without creating an array we would cause an endless loop...
	
	NSMutableArray* objects = [NSMutableArray array];
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// Setup the loop
	
	NSUInteger index = 0;
	NSString* thumbnailPath = nil;
	IMBFaceNodeObject* object = nil;
	NSString* subNodeType = @"Face";
	
	for (id faceDict in sortedFaces)
	{
		NSString* subnodeName = [faceDict objectForKey:@"name"];
		
		if ([self shouldUseAlbumType:subNodeType] && 
			[self shouldUseAlbum:faceDict images:inImages])
		{
            // Validate node dictionary and repair if necessary
            // For that we need a mutable version of node dictionary
            
            faceDict = [NSMutableDictionary dictionaryWithDictionary:faceDict];
            
			// Adjust keys "KeyPhotoKey", "KeyList", and "PhotoCount" in metadata dictionary
			// because movies and images are not jointly displayed in iMedia browser...
			
			[faceDict addEntriesFromDictionary:[self childrenInfoForNode:faceDict images:inImages]];
			
            if (![self ensureValidKeyPhotoKeyForSkimmableNode:faceDict relativeToMasterImageList:inImages]) {
                continue;
            }
            
			// Create subnode for this node...
			
			IMBNode* subnode = [[[IMBNode alloc] initWithParser:self topLevel:NO] autorelease];
			
			subnode.isLeafNode = [self isLeafAlbumType:subNodeType];
			subnode.icon = [self iconForAlbumType:subNodeType highlight:NO];
			subnode.highlightIcon = [self iconForAlbumType:subNodeType highlight:YES];
			subnode.name = subnodeName;
			subnode.isIncludedInPopup = NO;
			subnode.watchedPath = inNode.watchedPath;	// These two lines are important to make file watching work for nested 
			subnode.watcherType = kIMBWatcherTypeNone;  // subfolders. See IMBLibraryController _reloadNodesWithWatchedPath:
			
			// Keep a ref to face dictionary for potential later use
			subnode.attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                  faceDict, @"nodeSource",
                                  [self nodeTypeForNode:subnode], @"nodeType", nil];
			
			// Set the node's identifier. This is needed later to link it to the correct parent node.
			// Note that a faces dictionary always has a "key" key...
			
			NSNumber* subnodeId = [faceDict objectForKey:@"key"];
			subnode.identifier = [self identifierForId:subnodeId inSpace:FACES_ID_SPACE];
			
			// Add the new subnode to its parent (inRootNode)...
			
			[subnodes addObject:subnode];
			
			// Now create the visual object and link it to subnode just created
			
			object = [[IMBFaceNodeObject alloc] init];
			[objects addObject:object];
			[object release];
			
			object.preliminaryMetadata = faceDict;	// This metadata from the XML file is available immediately
            [object resetCurrentSkimmingIndex];                 // Must be done *after* preliminaryMetadata is set
			object.metadata = nil;								// Build lazily when needed (takes longer)
			object.metadataDescription = nil;					// Build lazily when needed (takes longer)
			
			object.representedNodeIdentifier = subnode.identifier;
            
            // NOTE: Since faces represent multiple resources we do not set their "location" property

			object.name = subnode.name;
			object.parserIdentifier = [self identifier];
			object.index = index++;
			
			thumbnailPath = [self imagePathForFaceIndex:[faceDict objectForKey:@"key image face index"]
                                         inImageWithKey:[faceDict objectForKey:@"KeyPhotoKey"]];
			object.imageLocation = (id)[NSURL fileURLWithPath:thumbnailPath isDirectory:NO];
			object.imageRepresentationType = [self requestedImageRepresentationType];
			object.imageRepresentation = nil;
		}
	}	
	
	[pool drain];
	inNode.objects = objects;
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Convenience

//----------------------------------------------------------------------------------------------------------------------
// Returns events id space  (EVENTS_ID_SPACE) for album types "Face" and "Faces".
// Returns faces id space  (FACES_ID_SPACE) for album types "Face" and "Faces".
// Otherwise returns the albums id space (ALBUMS_ID_SPACE).

- (NSString*) idSpaceForAlbumType:(NSString*) inAlbumType
{
	if ([inAlbumType isEqualToString:@"Event"] || [inAlbumType isEqualToString:@"Events"])
	{
		return EVENTS_ID_SPACE;
	} else if ([inAlbumType isEqualToString:@"Face"] || [inAlbumType isEqualToString:@"Faces"])
	{
		return FACES_ID_SPACE;
	} else if ([inAlbumType isEqualToString:@"Photo Stream"])
    {
        return PHOTO_STREAM_ID_SPACE;
    }
	return ALBUMS_ID_SPACE;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether an album of this type exposes a disclosure triangle or not.

- (BOOL) isLeafAlbumType:(NSString*)inType
{
	return ![inType isEqualToString:@"Folder"] &&
	![inType isEqualToString:@"Events"] &&
	![inType isEqualToString:@"Faces"];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns an album found in the album list in its plist representation based on a blocks boolean return value.
// Will also return the index where it is to be found as reference.

- (NSUInteger) indexOfAlbumInAlbumList:(NSArray*)inAlbumList passingTest:(SEL)predicateSelector
{
    // Transform predicate into block (needed by -[indexOfObjectPassingTest]:)
    
    BOOL(^listPredicate)(id, NSUInteger, BOOL *) = ^(id albumDict, NSUInteger idx, BOOL *stop)
    {
		if ([self performSelector:predicateSelector withObject:albumDict])
		{
			*stop = YES;
			return YES;
		}
        return NO;
    };
    
    return [inAlbumList indexOfObjectPassingTest:listPredicate];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the index of the all photos album ("Photos") in given album list

- (NSUInteger) indexOfAllPhotosAlbumInAlbumList:(NSArray*)inAlbumList
{
    return [self indexOfAlbumInAlbumList:inAlbumList passingTest:@selector(isAllPhotosAlbum:)];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the index of the projects album ("Projects") in given album list
// Projects are to Aperture what events are to iPhoto - hence the method name for coherence

- (NSUInteger) indexOfEventsAlbumInAlbumList:(NSArray*)inAlbumList
{
    return [self indexOfAlbumInAlbumList:inAlbumList passingTest:@selector(isEventsAlbum:)];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns the index of the flagged album ("Flagged") in given album list

- (NSUInteger) indexOfFlaggedAlbumInAlbumList:(NSArray*)inAlbumList
{
    return [self indexOfAlbumInAlbumList:inAlbumList passingTest:@selector(isFlaggedAlbum:)];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns IKImageBrowserCGImageRepresentationType

- (NSString*) requestedImageRepresentationType
{
	return IKImageBrowserNSDataRepresentationType;
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inNode has id x and belongs to id space y

- (BOOL) isNode:(IMBNode*)inNode withId:(NSUInteger)inId inSpace:(NSString *)inIdSpace
{	
	NSNumber* nodeId = [NSNumber numberWithUnsignedInt:inId];
	NSString* nodeIdentifier = [self identifierForId:nodeId inSpace:inIdSpace];
	
	return [inNode.identifier isEqualToString:nodeIdentifier];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inNode is the events node

- (BOOL) isEventsNode:(IMBNode*)inNode
{	
	return [self isNode:inNode withId:EVENTS_NODE_ID inSpace:EVENTS_ID_SPACE];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inNode is the faces node

- (BOOL) isFacesNode:(IMBNode*)inNode
{	
	return [self isNode:inNode withId:FACES_NODE_ID inSpace:FACES_ID_SPACE];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns whether inNode is the Photo Stream node

- (BOOL) isPhotoStreamNode:(IMBNode*)inNode
{	
	return [self isNode:inNode withId:PHOTO_STREAM_NODE_ID inSpace:PHOTO_STREAM_ID_SPACE];
}


//----------------------------------------------------------------------------------------------------------------------
// Returns node types for events node and faces node. nil otherwise.

- (NSString *)nodeTypeForNode:(IMBNode *)inNode
{
    if ([self isEventsNode:inNode]) return kIMBiPhotoNodeObjectTypeEvent;
    if ([self isFacesNode:inNode]) return kIMBiPhotoNodeObjectTypeFace;
    return nil;
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark - Library version specifics

// Get album type

- (NSString*) typeForAlbum:(NSDictionary*)album
{
    NSString* albumType = [album valueForKey:@"Album Type"];
    
    // Last import
    
    if ([[album valueForKey:@"uuid"] isEqualToString:@"lastImportAlbum"] ||                 // Aperture 3.4, iPhoto 9.4
        [albumType isEqualToString:@"Special Roll"])                                        // iPhoto 8.1.2
    {
        return @"Last Import";
    }
    return albumType;
}


//----------------------------------------------------------------------------------------------------------------------

#pragma mark - Library consistency

// Checks inKey whether it is a valid key in resource list and returns it if valid.
// If not checks all other candidates for validity and returns the first that is valid.
// If not returns nil.

- (NSString *)validatedResourceKey:(NSString *)inKey relativeToResourceList:(NSDictionary *)inResources otherCandidates:(NSArray *)inKeyList
{
    if ([inResources objectForKey:inKey]) return inKey;

    for (id aKey in inKeyList)
    {
        if ([inResources objectForKey:aKey]) return aKey;
    }
    return nil;
}

// Tries to ensure that a skimmable node (face or event or project) has a valid key photo key (in terms of
// exists in master image list). Will replace that key if invalid with any other valid key of that node.
// Returns NO if no valid key was found, otherwise returns YES.
// NOTE: inNodeDict must have the following keys: "name" or "RollName", "KeyPhotoKey", "KeyList"

- (BOOL)ensureValidKeyPhotoKeyForSkimmableNode:(NSMutableDictionary *)ioNodeDict
                     relativeToMasterImageList:(NSDictionary *)inMasterImages
{
    // Check for valid key photo key in node dict and try to replace with some other if necessary
    // (We've had occurences where key photo key was invalid (not key in master image list))
    
    NSString* keyPhotoKeyCandidate = [ioNodeDict objectForKey:@"KeyPhotoKey"];
    NSString* validKeyPhotoKey = [self validatedResourceKey:keyPhotoKeyCandidate
                                     relativeToResourceList:inMasterImages
                                            otherCandidates:[ioNodeDict objectForKey:@"KeyList"]];
    
    if (!validKeyPhotoKey)
    {
        NSString *nodeName = [ioNodeDict objectForKey:@"name"] ?
                             [ioNodeDict objectForKey:@"name"] :
                             [ioNodeDict objectForKey:@"RollName"];
        
        NSLog(@"%s Could not create skimmable node %@ because could not determine key photo", __FUNCTION__, nodeName);
        return NO;
    }
    
    if (![keyPhotoKeyCandidate isEqualToString:validKeyPhotoKey])
    {
        // Replace
        [ioNodeDict setObject:validKeyPhotoKey forKey:@"KeyPhotoKey"];
    }
    return YES;
}

// Some album names in AlbumData.xml and ApertureData.xml don't seem to be localized anymore (e.g. iPhoto 9.4)
// We localize them ourselves.

- (NSString*) localizedNameForAlbumName:(NSString*)albumName
{
    if ([albumName isEqualToString:@"Photos"])
        return NSLocalizedStringWithDefaultValue(@"IMBAppleMediaParser.allPhotos", nil, IMBBundle(), @"Photos", @"'Photos' node in Aperture or iPhoto");
    else if ([albumName isEqualToString:@"Flagged"])
        return NSLocalizedStringWithDefaultValue(@"IMBAppleMediaParser.flagged", nil, IMBBundle(), @"Flagged", @"'Flagged' node in Aperture or iPhoto");
    else if ([albumName isEqualToString:@"Last Import"])
        return NSLocalizedStringWithDefaultValue(@"IMBAppleMediaParser.lastImport", nil, IMBBundle(), @"Last Import", @"'Last Import' node in Aperture or iPhoto");
    else if ([albumName isEqualToString:@"Last 12 Months"])
        return NSLocalizedStringWithDefaultValue(@"IMBAppleMediaParser.last12Months", nil, IMBBundle(), @"Last 12 Months", @"'Last 12 Months' node in Aperture or iPhoto");
    else return albumName;
}


@end
