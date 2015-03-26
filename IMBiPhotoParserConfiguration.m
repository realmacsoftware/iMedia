//
//  IMBiPhotoParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.03.15.
//
//

#import "IMBiPhotoParserConfiguration.h"
#import "NSImage+iMedia.h"

/**
 Attribute keys supported by iPhoto media source (as of OS X 10.10.3)
 */
NSString *kIMBiPhotoMediaGroupIdentifierEvents = @"AllProjectsItem";
NSString *kIMBiPhotoMediaGroupIdentifierPhotos = @"allPhotosAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierFaces = @"peopleAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierPlaces = @"allPlacedPhotosAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierLast12Months = @"lastNMonthsAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierLastImport = @"lastImportAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierFlagged = @"flaggedAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierEventFilterBar = @"eventFilterBarAlbum";

/**
 Parser configuration factory for Apple iPhoto app.
 */
IMBMLParserConfigurationFactory IMBMLiPhotoParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:
                                                kIMBiPhotoMediaGroupIdentifierEvents,
                                                kIMBiPhotoMediaGroupIdentifierPhotos,
                                                kIMBiPhotoMediaGroupIdentifierFaces,
                                                kIMBiPhotoMediaGroupIdentifierPlaces,
                                                kIMBiPhotoMediaGroupIdentifierLast12Months,
                                                kIMBiPhotoMediaGroupIdentifierLastImport,
                                                kIMBiPhotoMediaGroupIdentifierFlagged,
                                                nil];
    
    return [[IMBiPhotoParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceiPhotoIdentifier
                                                               AppleMediaLibraryMediaType:mediaType
                                                        identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBiPhotoParserConfiguration

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from iPhoto library representation (MLMediaObject.attributes) to iMedia representation
    
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionaryWithDictionary:inObject.preliminaryMetadata];
    
    [externalMetadata addEntriesFromDictionary:[NSImage imb_metadataFromImageAtURL:inObject.URL checkSpotlightComments:NO]];
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"iPhoto";
}

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
                                          kIMBiPhotoMediaGroupIdentifierEventFilterBar,
                                          nil];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet setWithObjects:
//                                        kIMBiPhotoMediaGroupIdentifierEvents,
                                        kIMBiPhotoMediaGroupIdentifierPhotos,
                                        nil];
    
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}

- (MLMediaObject *)keyMediaObjectForMediaGroup:(MLMediaGroup *)mediaGroup fromMediaSource:(MLMediaSource *)mediaSource
{
    NSString *keyPhotoKey = mediaGroup.attributes[@"KeyPhotoKey"];
    
    if (keyPhotoKey) {
        return [mediaSource mediaObjectForIdentifier:keyPhotoKey];
    }
    return nil;
}
@end
