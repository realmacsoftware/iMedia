//
//  IMBiTunesParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.03.15.
//
//

#import "IMBiTunesParserConfiguration.h"

/**
 Parser configuration factory for Apple iTunes app.
 */
IMBMLParserConfigurationFactory IMBMLiTunesParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:nil];
    
    return [[IMBiTunesParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceiTunesIdentifier
                                                    AppleMediaLibraryMediaType:mediaType
                                             identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBiTunesParserConfiguration

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from iPhoto library representation (MLMediaObject.attributes) to iMedia representation
    
//    NSDictionary *internalMetadata = inObject.preliminaryMetadata;
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionary];
    
    // Add iTunes-specific entries to external dictionary here
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"iTunes (Apple Media Library)";
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
    
    //    NSLog(@"Identifier for media group %@: %@", mediaGroup.name, mediaGroup.identifier);
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}
@end
