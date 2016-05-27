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
^id<IMBAppleMediaLibraryParserDelegate>(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet set];
    
    return [[IMBiTunesParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceiTunesIdentifier
                                                    AppleMediaLibraryMediaType:mediaType
                                             identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBiTunesParserConfiguration

/**
 */
- (NSDictionary *)metadataForMediaObject:(MLMediaObject *)mediaObject
{
    // Map metadata information from iTunes library representation to iMedia representation
    
    NSDictionary *internalMetadata = mediaObject.attributes;
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionary];
    
    double duration = [[internalMetadata objectForKey:@"Total Time"] doubleValue] / 1000.0;
    [externalMetadata setObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
    
    NSString* artist = [internalMetadata objectForKey:@"Artist"];
    if (artist) [externalMetadata setObject:artist forKey:@"artist"];
    
    NSString* album = [internalMetadata objectForKey:@"Album"];
    if (album) [externalMetadata setObject:album forKey:@"album"];
    
    NSString* genre = [internalMetadata objectForKey:@"Genre"];
    if (genre) [externalMetadata setObject:genre forKey:@"genre"];
    
//    NSString* comment = [internalMetadata objectForKey:@"Comment"];
//    if (comment) [externalMetadata setObject:comment forKey:@"comment"];
    
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"iTunes";
}

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet set];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet set];
    
    //    NSLog(@"Identifier for media group %@: %@", mediaGroup.name, mediaGroup.identifier);
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}

- (BOOL)shouldUseChildGroupsAsMediaObjectsForMediaGroup:(MLMediaGroup *)mediaGroup
{
    return NO;
}

- (NSImage *)thumbnailForMediaGroup:(MLMediaGroup *)mediaGroup
{
    return nil;
}

@end
