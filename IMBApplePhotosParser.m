//
//  IMBApplePhotosParser.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import "IMBApplePhotosParser.h"

/**
 Attribute key supported by Photos media source (as of OS X 10.10.3)
 */
NSString *kIMBMediaSourceAttributeLibraryURL = @"libraryURL";

NSString *kIMBPhotosMediaGroupIdentifierMoments = @"AllMomentsGroup";
NSString *kIMBPhotosMediaGroupIdentifierCollections = @"AllCollectionsGroup";
NSString *kIMBPhotosMediaGroupIdentifierYears = @"AllYearsGroup";
NSString *kIMBPhotosMediaGroupIdentifierPlaces = @"allPlacedPhotosAlbum";
NSString *kIMBPhotosMediaGroupIdentifierShared = @"com.apple.Photos.SharedGroup";
NSString *kIMBPhotosMediaGroupIdentifierAlbums = @"TopLevelAlbums";

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

#pragma mark Configuration

/**
 Returns the identifier for the app that is associated with sources handled by the parser.
 */
+ (NSString *)mediaSourceIdentifier
{
    return MLMediaSourcePhotosIdentifier;
}

/**
 Returns the URL denoting the actual media source on disk. Must be subclassed.
 
 @discussion
 If the URL is not accessible to a concrete parser it may return nil but implications of doing so are not yet fully understood.
 */
- (NSURL *)mediaSourceURLForGroup:(MLMediaGroup *)mediaGroup
{
    return self.AppleMediaSource.attributes[kIMBMediaSourceAttributeLibraryURL];
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

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
                                         kIMBPhotosMediaGroupIdentifierMoments,
                                         kIMBPhotosMediaGroupIdentifierCollections,
                                         nil];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet setWithObjects:
                                        kIMBPhotosMediaGroupIdentifierMoments,
                                        kIMBPhotosMediaGroupIdentifierCollections,
                                        kIMBPhotosMediaGroupIdentifierYears,
                                        nil];
    
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}
@end
