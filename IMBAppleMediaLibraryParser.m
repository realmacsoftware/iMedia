//
//  IMBAppleMediaLibraryParser.m
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import "NSObject+iMedia.h"
#import "NSWorkspace+iMedia.h"
#import "NSURL+iMedia.h"
#import "IMBNodeObject.h"
#import "IMBAppleMediaLibraryParser.h"
#import "IMBAppleMediaLibraryPropertySynchronizer.h"

@implementation IMBAppleMediaLibraryParser

@synthesize AppleMediaLibrary = _AppleMediaLibrary;
@synthesize AppleMediaSource = _AppleMediaSource;
@synthesize appPath = _appPath;

/**
 Returns the identifier for the app that is associated with sources handled by the parser. Must be subclassed.
 
 @see MLMediaLibrary media source identifiers
 */
+ (NSString *)mediaSourceIdentifier
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return nil;
}

/**
 Internal media type is specific to Apple Media Library based parsers and not to be confused with kIMBMediaTypeImage and its siblings. Must be subclassed.
 */
+ (MLMediaType)internalMediaType
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return 0;
}

/**
 Returns the URL denoting the actual media source on disk. Must be subclassed.
 
 @discussion
 If the URL is not accessible to a concrete parser it may return nil but implications of doing so are not yet fully understood.
 */
- (NSURL *)mediaSourceURLForGroup:(MLMediaGroup *)mediaGroup
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return nil;
}

/**
 */
- (instancetype)initializeMediaLibrary
{
    NSDictionary *libraryOptions = @{MLMediaLoadIncludeSourcesKey : [NSArray arrayWithObject:[[self class] mediaSourceIdentifier]]};
    self.AppleMediaLibrary = [[MLMediaLibrary alloc] initWithOptions:libraryOptions];
    NSDictionary *mediaSources = [IMBAppleMediaLibraryPropertySynchronizer mediaSourcesForMediaLibrary:self.AppleMediaLibrary];
    self.AppleMediaSource = mediaSources[[[self class] mediaSourceIdentifier]];
    
    return self;
}

#pragma mark - Mandatory overrides from superclass we can handle here

/**
 */
- (IMBNode *)unpopulatedTopLevelNode:(NSError **)outError
{
    NSError *error = nil;
    
    // (Re-)instantiate media library and media source (in Apple speak), because content might have changed on disk. Note though that this yet doesn't seem to have an effect when media library changes (Apple doesn't seem to update its object cache).
    [self initializeMediaLibrary];
    
    MLMediaGroup *rootMediaGroup = [IMBAppleMediaLibraryPropertySynchronizer rootMediaGroupForMediaSource:self.AppleMediaSource];
    
    // Is there a matching media source?
    
    if (!rootMediaGroup) return nil;

    // Assign media source URL as late as possible since some media sources only provide it through attributes dictionary of root media group (e.g. iPhoto)
    self.mediaSource = [self mediaSourceURLForGroup:rootMediaGroup];
    
    //  create an empty root node (unpopulated and without subnodes)
    
    IMBNode *node = [[IMBNode alloc] initWithParser:self topLevel:YES];
    node.name = [self libraryName];
    node.groupType = kIMBGroupTypeLibrary;
    node.icon = [[NSWorkspace imb_threadSafeWorkspace] iconForFile:self.appPath];
    node.isIncludedInPopup = YES;
    node.isLeafNode = NO;
    node.mediaSource = self.mediaSource;
    node.accessibility = self.mediaSource ? [self mediaSourceAccessibility] : kIMBResourceIsAccessible;
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
            
//            NSLog(@"Media object URL: %@", [object location]);
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
    NSString *mediaSourcePath = [self.mediaSource path];
    return mediaSourcePath ? mediaSourcePath : [[self class] mediaSourceIdentifier];
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
    
    [URL startAccessingSecurityScopedResource];
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
