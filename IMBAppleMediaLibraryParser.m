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

#define CREATE_MEDIA_OBJECTS_CONCURRENTLY 0

#define MEASURE_EXECUTION_TIME 1

#if MEASURE_EXECUTION_TIME
    #define START_MEASURE(id) NSDate *start ## id = [NSDate date]
    #define STOP_MEASURE(id)  NSDate *stop ## id  = [NSDate date]
    #define LOG_MEASURED_TIME(id, ...) NSLog(@"Took %f secs to execute %@", [stop ## id timeIntervalSinceDate:start ## id], [NSString stringWithFormat: __VA_ARGS__])
#else
    #define START_MEASURE(id)
    #define STOP_MEASURE(id)
    #define LOG_MEASURED_TIME(id, ...)
#endif

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
    node.identifier = [self globalIdentifierForMediaGroup:rootMediaGroup];
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
    if (!inParentNode.objects) {
        // Create the objects array on demand  - even if turns out to be empty after exiting this method, because without creating an array we would cause an endless loop...
        
        NSMutableArray* objects = [NSMutableArray array];
        
        START_MEASURE(1);
        NSArray *mediaObjects = [IMBAppleMediaLibraryPropertySynchronizer mediaObjectsForMediaGroup:parentGroup];
        STOP_MEASURE(1);
        LOG_MEASURED_TIME(1, @"fetch of media Objects for group %@", parentGroup.name);
        
#if CREATE_MEDIA_OBJECTS_CONCURRENTLY
        dispatch_group_t dispatchGroup = dispatch_group_create();
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(8);
#endif
        
        START_MEASURE(2);
        
        for (MLMediaObject *mediaObject in mediaObjects)
        {
#if CREATE_MEDIA_OBJECTS_CONCURRENTLY
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#endif
                if ([self shouldUseMediaObject:mediaObject])
                {
                    
                    IMBObject *object = [self objectForMediaObject:mediaObject];
                    
                    @synchronized(objects) {
                        [objects addObject:object];
                    }
                }
#if CREATE_MEDIA_OBJECTS_CONCURRENTLY
                dispatch_semaphore_signal(semaphore);
            });
#endif
        }
#if CREATE_MEDIA_OBJECTS_CONCURRENTLY
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        dispatch_release(dispatchGroup);
        dispatch_release(semaphore);
#endif
        inParentNode.objects = objects;
        
        STOP_MEASURE(2);
        LOG_MEASURED_TIME(2, @"IMBObjects creation for group %@", parentGroup.name);
    }
    
    NSMutableArray* subnodes = [inParentNode mutableArrayForPopulatingSubnodes];
    NSArray *childGroups = [parentGroup childGroups];
    
    NSLog(@"Group %@ has %zd child groups", parentGroup.name, [childGroups count]);
    
    START_MEASURE(3);
    
    for (MLMediaGroup *mediaGroup in childGroups) {
        
        if ([self shouldUseMediaGroup:mediaGroup]) {
            // Create node for this album...
            
            IMBNode *childNode = [self nodeForParentNode:inParentNode MediaGroup:mediaGroup];
            
            // Optimization for subnodes that share the same media objects with their parent node
            
            if ([self shouldReuseMediaObjectsOfParentGroupForGroup:mediaGroup]) {
                childNode.objects = inParentNode.objects;
                [self populateNode:childNode error:&error];
            }
            
            // Add the new album node to its parent (inRootNode)...
            
            [subnodes addObject:childNode];
            
            //        NSLog(@"Subgroup of Photos root node: %@", [mediaGroup name]);
            
        }
    }
    STOP_MEASURE(3);
    LOG_MEASURED_TIME(3, @"subnodes creation for group %@", parentGroup.name);
    
    if (*outError) *outError = error;
    return YES;
}


//
//
- (id)thumbnailForObject:(IMBObject *)inObject error:(NSError **)outError
{
    NSError *error = nil;
    
    // IKImageBrowser can also deal with NSData type (IKImageBrowserNSDataRepresentationType)
    
    NSURL *url = nil;
    if (inObject.imageLocation)
    {
        url = [self URLForBookmark:(NSData *)inObject.imageLocation error:&error];
    } else {
        MLMediaObject *mediaObject = [self mediaObjectForObject:inObject];
        url = mediaObject.thumbnailURL;
    }
    
    if (url) {
        id thumbnail = nil;
        
        [url startAccessingSecurityScopedResource];
        
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
        [url stopAccessingSecurityScopedResource];
        
        return thumbnail;
    } else {
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
 Converts an MLMediaLibrary group into iMedia's "native" IMBNode.
 */
- (IMBNode *)nodeForParentNode:(IMBNode *)parentNode MediaGroup:(MLMediaGroup *)mediaGroup
{
    IMBNode* node = [[IMBNode alloc] initWithParser:self topLevel:NO];
    
    node.isLeafNode = [[mediaGroup childGroups] count] == 0;
    node.icon = [IMBAppleMediaLibraryPropertySynchronizer iconImageForMediaGroup:mediaGroup];
// albumNode.highlightIcon = ...;
    node.name = [mediaGroup name];
    node.watchedPath = parentNode.watchedPath;	// These two lines are important to make file watching work for nested
    node.watcherType = kIMBWatcherTypeNone;     // subfolders. See IMBLibraryController _reloadNodesWithWatchedPath:
    
    node.identifier = [self globalIdentifierForMediaGroup:mediaGroup];
    
    return node;
}

/**
 */
- (MLMediaGroup *)mediaGroupForNode:(IMBNode *)node
{
    NSString *mediaGroupIdentifier = [node.identifier stringByReplacingOccurrencesOfString:[self identifierPrefix] withString:@""];
    return [self.AppleMediaSource mediaGroupForIdentifier:mediaGroupIdentifier];
}

/**
 Returns whether the node given should be shown in the node hierarchy.
 
 @discussion
 This implementation always returns YES. You are welcome to override in your subclass parser.
 */
- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    return YES;
}

/**
 Returns whether the group given should use the same media objects as its parent.
 
 @discussion
 This implementation always returns NO. You are welcome to override in your subclass parser (will boost performance).
 */
- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    return NO;
}

- (NSString *)globalIdentifierForMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSParameterAssert(mediaGroup.identifier != nil);
    
    if (mediaGroup.identifier) {
        return [[self identifierPrefix] stringByAppendingString:mediaGroup.identifier];
    } else {
        NSLog(@"%s: media group %@ has no identifier", __FUNCTION__, mediaGroup.name);
        return [self identifierPrefix];
    }
}

#pragma mark - Media Object

/**
 Converts an MLMediaLibrary object into iMedia's "native" IMBObject.
 */
 - (IMBObject *)objectForMediaObject:(MLMediaObject *)mediaObject
{
    IMBObject *object = [[IMBObject alloc] init];
    
    object.identifier = mediaObject.identifier;
    object.parserIdentifier = [self identifier];
    object.accessibility = kIMBResourceIsAccessible;
    object.name = [self nameForMediaObject:mediaObject];
    object.location = mediaObject.URL;
    
// Since the following two operations are expensive we postpone them to the point when we actually need the data
//    object.locationBookmark = [self bookmarkForURL:mediaObject.URL error:&error];
//    object.imageLocation = [self bookmarkForURL:mediaObject.thumbnailURL error:&error];
    
    object.imageRepresentationType = IKImageBrowserNSImageRepresentationType;
    object.preliminaryMetadata = mediaObject.attributes;
    
//    NSLog(@"Media object URL: %@", [object location]);
    return object;
}

/**
 Fetches the object from Apple's media library that corresponds to iMedia's "native" IMBObject.
 */
- (MLMediaObject *)mediaObjectForObject:(IMBObject *)object
{
    return [self.AppleMediaSource mediaObjectForIdentifier:object.identifier];
}

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
