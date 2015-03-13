//
//  IMBApplePhotosParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.03.15.
//
//

#import "IMBApplePhotosParserConfiguration.h"

/**
 Reverse-engineered keys of the Photos app media source's attributes.
 
 Apple doesn't seem to yet publicly define these constants anywhere.
 */
/* Top Level Groups*/
NSString *kIMBPhotosMediaGroupIdentifierMoments = @"AllMomentsGroup";
NSString *kIMBPhotosMediaGroupIdentifierCollections = @"AllCollectionsGroup";
NSString *kIMBPhotosMediaGroupIdentifierYears = @"AllYearsGroup";
NSString *kIMBPhotosMediaGroupIdentifierPlaces = @"allPlacedPhotosAlbum";
NSString *kIMBPhotosMediaGroupIdentifierShared = @"com.apple.Photos.SharedGroup";
NSString *kIMBPhotosMediaGroupIdentifierAlbums = @"TopLevelAlbums";

/* Albums */
NSString *kIMBPhotosMediaGroupIdentifierAllPhotos = @"allPhotosAlbum";
NSString *kIMBPhotosMediaGroupIdentifierPeople= @"peopleAlbum";
NSString *kIMBPhotosMediaGroupIdentifierLastImport = @"lastImportAlbum";
NSString *kIMBPhotosMediaGroupIdentifierFavorites = @"favoritesAlbum";
NSString *kIMBPhotosMediaGroupIdentifierPanoramas = @"panoramaAlbum";
NSString *kIMBPhotosMediaGroupIdentifierVideos = @"videoAlbum";
NSString *kIMBPhotosMediaGroupIdentifierSloMos = @"videoSloMoAlbum";
NSString *kIMBPhotosMediaGroupIdentifierBursts = @"burstAlbum";

/**
 Parser configuration factory for Apple Photos app.
 */
IMBMLParserConfigurationFactory IMBMLPhotosParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:
                                                kIMBPhotosMediaGroupIdentifierMoments,
                                                kIMBPhotosMediaGroupIdentifierCollections,
                                                kIMBPhotosMediaGroupIdentifierYears,
                                                kIMBPhotosMediaGroupIdentifierPlaces,
                                                kIMBPhotosMediaGroupIdentifierShared,
                                                kIMBPhotosMediaGroupIdentifierAlbums,
                                                
                                                kIMBPhotosMediaGroupIdentifierAllPhotos,
                                                kIMBPhotosMediaGroupIdentifierPeople,
                                                kIMBPhotosMediaGroupIdentifierLastImport,
                                                kIMBPhotosMediaGroupIdentifierFavorites,
                                                kIMBPhotosMediaGroupIdentifierPanoramas,
                                                kIMBPhotosMediaGroupIdentifierVideos,
                                                kIMBPhotosMediaGroupIdentifierSloMos,
                                                kIMBPhotosMediaGroupIdentifierBursts,
                                                nil];
    
    
    return [[IMBApplePhotosParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourcePhotosIdentifier
                                                         AppleMediaLibraryMediaType:mediaType
                                                  identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBApplePhotosParserConfiguration

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
- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
//                                          kIMBPhotosMediaGroupIdentifierMoments,
//                                          kIMBPhotosMediaGroupIdentifierCollections,
                                          nil];
    switch (self.mediaType) {
        case MLMediaTypeImage:
            unqualifiedGroupIdentifiers = [unqualifiedGroupIdentifiers
                                           setByAddingObjectsFromSet:[NSSet setWithObjects:
                                                                      kIMBPhotosMediaGroupIdentifierSloMos,
                                                                      kIMBPhotosMediaGroupIdentifierVideos,
                                                                      nil]];
            break;
            
        case MLMediaTypeMovie:
            unqualifiedGroupIdentifiers = [unqualifiedGroupIdentifiers
                                           setByAddingObjectsFromSet:[NSSet setWithObjects:
                                                                      kIMBPhotosMediaGroupIdentifierPanoramas,
                                                                      kIMBPhotosMediaGroupIdentifierBursts,
                                                                      nil]];
            break;
            
        default:
            break;
    }
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

/**
 */
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
