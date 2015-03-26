//
//  IMBApertureParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 11.03.15.
//
//

#import "IMBApertureParserConfiguration.h"
#import "NSImage+iMedia.h"

/**
 Parser configuration factory for Apple iPhoto app.
 */
IMBMLParserConfigurationFactory IMBMLApertureParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:
                                                nil];
    
    return [[IMBApertureParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceApertureIdentifier
                                                    AppleMediaLibraryMediaType:mediaType
                                             identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBApertureParserConfiguration

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from Aperture library representation (MLMediaObject.attributes) to iMedia representation
    
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionaryWithDictionary:inObject.preliminaryMetadata];
    
    [externalMetadata addEntriesFromDictionary:[NSImage imb_metadataFromImageAtURL:inObject.URL checkSpotlightComments:NO]];
    
    // Add Aperture-specific entries to external dictionary here
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"Aperture";
}

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
                                          nil];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet setWithObjects:
                                        nil];
    
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}

@end
