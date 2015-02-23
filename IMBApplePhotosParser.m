//
//  IMBApplePhotosParser.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import "NSObject+iMedia.h"
#import "NSWorkspace+iMedia.h"
#import "NSURL+iMedia.h"
#import "IMBAppleMediaLibraryPropertySynchronizer.h"
#import "IMBApplePhotosParser.h"
#import "IMBNodeObject.h"

#define MEDIA_SOURCE_IDENTIFIER MLMediaSourcePhotosIdentifier

/**
 Reverse-engineered keys of the Photos app media source's attributes.
 
 Apple doesn't seem to yet publicly define these constants anywhere.
 */
NSString *kIMBMediaSourceAttributeIdentifier = @"mediaSourceIdentifier";

/**
 Only supported by Photos media source (as of OS X 10.10.3)
 */
NSString *kIMBMediaSourceAttributeLibraryURL = @"libraryURL";

#pragma mark -

@implementation IMBApplePhotosImageParser

#pragma mark Configuration

/**
 Internal media type is specific to Apple Media Library based parsers and is not to be confused with kIMBMediaTypeImage and its siblings.
 */
+ (MLMediaType)internalMediaType
{
    return MLMediaTypeImage;
}

/**
 See implementation of this method in IMBParser for what this is about. Resist the temptation of using -classname since a class name might change over time but this identifier prefix must not!
 */
- (NSString*) iMedia2PersistentResourceIdentifierPrefix
{
    return @"IMBApplePhotosImageParser";
}

@end

#pragma mark -

@implementation IMBApplePhotosMovieParser

#pragma mark Configuration

/**
 Internal media type is specific to Apple Media Library based parsers and is not to be confused with kIMBMediaTypeImage and its siblings.
 */
+ (MLMediaType)internalMediaType
{
    return MLMediaTypeMovie;
}

/**
 See implementation of this method in IMBParser for what this is about. Resist the temptation of using -classname since a class name might change over time but this identifier prefix must not!
 */
- (NSString*) iMedia2PersistentResourceIdentifierPrefix
{
    return @"IMBApplePhotosMovieParser";
}

@end

#pragma mark -

@implementation IMBApplePhotosParser

@synthesize AppleMediaLibrary = _AppleMediaLibrary;
@synthesize AppleMediaSource = _AppleMediaSource;
@synthesize appPath = _appPath;

/**
 Internal media type is specific to Apple Media Library based parsers and not to be confused with kIMBMediaTypeImage and its siblings. Must be subclassed.
 */
+ (MLMediaType)internalMediaType
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return 0;
}

/**
 */
- (instancetype)initializeMediaLibrary
{
    NSDictionary *libraryOptions = @{MLMediaLoadIncludeSourcesKey : @[MEDIA_SOURCE_IDENTIFIER]};
    self.AppleMediaLibrary = [[MLMediaLibrary alloc] initWithOptions:libraryOptions];
    NSDictionary *mediaSources = [IMBAppleMediaLibraryPropertySynchronizer mediaSourcesForMediaLibrary:self.AppleMediaLibrary];
    self.AppleMediaSource = mediaSources[MEDIA_SOURCE_IDENTIFIER];
    // Note that the following line is only proven to work for Photos app. Would have to use other means e.g. for iPhoto to provide path to media library (look in attributes dictionary for root group).
    self.mediaSource = self.AppleMediaSource.attributes[kIMBMediaSourceAttributeLibraryURL];
    
    return self;
}

#pragma mark - Mandatory overrides from superclass

/**
 */
- (IMBNode *)unpopulatedTopLevelNode:(NSError **)outError
{
    NSError *error = nil;
    
    // (Re-)instantiate media library and media source (in Apple speak), because content might have changed on disk. Note though that this yet doesn't seem to have an effect when media library changes (Apple doesn't seem to update its object cache).
    [self initializeMediaLibrary];
    
    MLMediaGroup *rootMediaGroup = [IMBAppleMediaLibraryPropertySynchronizer rootMediaGroupForMediaSource:self.AppleMediaSource];
    
    //  create an empty root node (unpopulated and without subnodes)
    
    IMBNode *node = [[IMBNode alloc] initWithParser:self topLevel:YES];
    node.name = [self libraryName];
    node.groupType = kIMBGroupTypeLibrary;
    node.icon = [[NSWorkspace imb_threadSafeWorkspace] iconForFile:self.appPath];
    node.isIncludedInPopup = YES;
    node.isLeafNode = NO;
    node.mediaSource = self.mediaSource;
    node.accessibility = [self mediaSourceAccessibility];
    node.isAccessRevocable = NO;
    node.identifier = [self globalIdentifierForLocalIdentifier:[rootMediaGroup identifier]];
    node.displayedObjectCount = 0;  // No media objects in top-level node
    
    if ([self mediaSourceAccessibility] == kIMBResourceIsAccessible) {
        node.watchedPath = [self.mediaSource path];
    }
    if (outError) {
        *outError = error;
    }
    return node;
}

/**
 */
- (BOOL) populateNode:(IMBNode *)inParentNode error:(NSError **)outError
{
    NSError *error = nil;
    MLMediaGroup *parentGroup = [self mediaGroupForNode:inParentNode];
    NSMutableArray* subnodes = [inParentNode mutableArrayForPopulatingSubnodes];
    
    for (MLMediaGroup *mediaGroup in [parentGroup childGroups]) {
        // Create node for this album...
        
        if ([self shouldUseMediaGroup:mediaGroup]) {
            IMBNode* albumNode = [[IMBNode alloc] initWithParser:self topLevel:NO];
            
            albumNode.isLeafNode = [[mediaGroup childGroups] count] == 0;
            albumNode.icon = [IMBAppleMediaLibraryPropertySynchronizer iconImageForMediaGroup:mediaGroup];
//            albumNode.highlightIcon = ...;
            albumNode.name = [mediaGroup name];
            albumNode.watchedPath = inParentNode.watchedPath;	// These two lines are important to make file watching work for nested
            albumNode.watcherType = kIMBWatcherTypeNone;        // subfolders. See IMBLibraryController _reloadNodesWithWatchedPath:
            
            albumNode.identifier = [self globalIdentifierForLocalIdentifier:[mediaGroup identifier]];
            
            // Add the new album node to its parent (inRootNode)...
            
            [subnodes addObject:albumNode];
            
            //        NSLog(@"Subgroup of Photos root node: %@", [mediaGroup name]);
        }
    }
    
    // Create the objects array on demand  - even if turns out to be empty after exiting this method, because without creating an array we would cause an endless loop...
    
    NSMutableArray* objects = [NSMutableArray array];
    
    NSArray *mediaObjects = [IMBAppleMediaLibraryPropertySynchronizer mediaObjectsForMediaGroup:parentGroup];
    
    for (MLMediaObject *mediaObject in mediaObjects)
    {
        if ([self shouldUseMediaObject:mediaObject])
        {
            IMBObject *object = [[IMBObject alloc] init];
            [objects addObject:object];
            
            object.parserIdentifier = [self identifier];
            object.accessibility = kIMBResourceIsAccessible;
            object.name = [self nameForMediaObject:mediaObject];
            object.location = mediaObject.URL;
            object.locationBookmark = [self bookmarkForURL:mediaObject.URL error:&error];
            object.imageLocation = [self bookmarkForURL:mediaObject.thumbnailURL error:&error];
            object.imageRepresentationType = IKImageBrowserNSImageRepresentationType;
            object.preliminaryMetadata = mediaObject.attributes;
            
            NSLog(@"Media object URL: %@", [object location]);
        }
    }
    inParentNode.objects = objects;
    
    if (*outError) *outError = error;
    return YES;
}


//
//
- (id)thumbnailForObject:(IMBObject *)inObject error:(NSError **)outError
{
    NSError *error = nil;
    
    // IKImageBrowser can also deal with NSData type (IKImageBrowserNSDataRepresentationType)
    
    if (inObject.imageLocation)
    {
        id thumbnail = nil;
        NSURL* url = [self URLForBookmark:(NSData *)inObject.imageLocation error:&error];
        
//        BOOL accessGranted = [url startAccessingSecurityScopedResource];
        
        if ([inObject.imageRepresentationType isEqualToString:IKImageBrowserNSImageRepresentationType]) {
            thumbnail = (id)[[NSImage alloc] initWithContentsOfURL:url];
        }
        else if ([inObject.imageRepresentationType isEqualToString:IKImageBrowserCGImageRepresentationType])
        {
            thumbnail = (id)[self thumbnailFromLocalImageFileForObject:inObject error:outError];
        }
        else
        {
            inObject.imageRepresentationType = IKImageBrowserNSDataRepresentationType;
            thumbnail = (id)[NSData dataWithContentsOfURL:url];
        }
//        [url stopAccessingSecurityScopedResource];
        
        return thumbnail;
    }
    else
    {
        inObject.imageRepresentationType = IKImageBrowserCGImageRepresentationType;
        return (id)[self thumbnailFromLocalImageFileForObject:inObject error:outError];
    }
    return nil;
}

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from Photos library representation (MLMediaObject.attributes) to iMedia representation
    NSDictionary *internalMetadata = inObject.preliminaryMetadata;
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionary];
    
    // Width, height
    
    NSString *resolutionString = internalMetadata[@"resolutionString"];
    if ([resolutionString isKindOfClass:[NSString class]]) {
        NSSize size = NSSizeFromString(resolutionString);
        externalMetadata[@"width"] = [NSString stringWithFormat:@"%d", (int)size.width];
        externalMetadata[@"height"] = [NSString stringWithFormat:@"%d", (int)size.height];
    }

    // Creation date and time
    
    id timeInterval = internalMetadata[@"DateAsTimerInterval"];
    NSString *timeIntervalString = nil;
    if ([timeInterval isKindOfClass:[NSNumber class]]) {
        timeIntervalString = [((NSNumber *)timeInterval) stringValue];
    } else if ([timeInterval isKindOfClass:[NSString class]]) {
        timeIntervalString = timeInterval;
    }
    if (timeIntervalString) {
        externalMetadata[@"dateTime"] = timeIntervalString;
    }
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 */
- (NSData*) bookmarkForObject:(IMBObject*)inObject error:(NSError**)outError
{
    NSError* error = nil;

    return[self bookmarkForURL:inObject.URL error:&error];
}

#pragma mark - Media Group

/**
 */
- (MLMediaGroup *)mediaGroupForNode:(IMBNode *)node
{
    NSString *mediaLibraryIdentifier = [node.identifier stringByReplacingOccurrencesOfString:[self identifierPrefix] withString:@""];
    return [self.AppleMediaSource mediaGroupForIdentifier:mediaLibraryIdentifier];
}

/**
 Returns YES if media group contains at least one media object of media type associated with the receiver. NO otherwise.
 */
- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    __block BOOL should = NO;
    
    // We should use this media group if it has at least one media object qualifying

    NSArray *mediaObjects = [IMBAppleMediaLibraryPropertySynchronizer mediaObjectsForMediaGroup:mediaGroup];
    
    [mediaObjects enumerateObjectsUsingBlock:^(MLMediaObject *mediaObject, NSUInteger idx, BOOL *stop) {
        if ([self shouldUseMediaObject:mediaObject]) {
            should = YES;
            *stop = YES;
        }
    }];
    
    return should;
}

#pragma mark - Media Object

/**
 */
- (BOOL)shouldUseMediaObject:(MLMediaObject *)mediaObject
{
    return ([[self class] internalMediaType] == mediaObject.mediaType);
}

/**
 */
- (NSString *)nameForMediaObject:(MLMediaObject *)mediaObject
{
    if (mediaObject.name) {
        return mediaObject.name;
    } else {
        return [[mediaObject.URL lastPathComponent] stringByDeletingPathExtension];
    }
}

/**
 Returns whether this object is hidden in Photos app (users can hide media objects in Photos app).
 @discussion
 Do not utilize this media object's property since media objects will already be treated by MediaLibrary framework according to their hidden status in Photos app. And hidden objects are not visible in Years/Collections/Moments but visible in albums by default.
 */
- (BOOL)hiddenMediaObject:(MLMediaObject *)mediaObject
{
    return [((NSNumber *)mediaObject.attributes[@"Hidden"]) boolValue];
}

#pragma mark - Utility

- (NSString *)libraryName
{
    return [[NSBundle bundleWithPath:self.appPath] localizedInfoDictionary][@"CFBundleDisplayName"];
}

- (NSString *)identifierPrefix
{
    return [self.mediaSource path];
}

- (NSString *)globalIdentifierForLocalIdentifier:(NSString *)identifier
{
    return [[self identifierPrefix] stringByAppendingString:identifier];
}

/**
 Returns a read-only app-security-scoped bookmark for URL.
 */
- (NSData *)bookmarkForURL:(NSURL *)URL error:(NSError *__autoreleasing *)outError
{
    NSError *error = nil;
    
    BOOL accessGranted = [URL startAccessingSecurityScopedResource];
    NSData *bookmark = [URL bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
    [URL stopAccessingSecurityScopedResource];
    
    if (outError) *outError = error;
    return bookmark;
}

/**
 Returns an app-security-scoped URL for bookmark.
 */
- (NSURL *)URLForBookmark:(NSData *)bookmark error:(NSError *__autoreleasing *)outError
{
    NSError *error = nil;
    BOOL stale = NO;
    
    NSURL *URL =[NSURL URLByResolvingBookmarkData:bookmark options:0 relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
    
    if (outError) *outError = error;
    return URL;
}
@end
