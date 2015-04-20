//
//  IMBAppleMediaLibraryParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 06.03.15.
//
//

#import "IMBAppleMediaLibraryParserConfiguration.h"
#import "IMBAppleMediaLibraryPropertySynchronizer.h"

@implementation IMBAppleMediaLibraryParserConfiguration

/**
 Designated initiliazer.
 */
- (instancetype)initWithMediaSourceIdentifier:(NSString *)mediaSourceIdentifier
                   AppleMediaLibraryMediaType:(MLMediaType)mediaType
            identifiersOfNonUserCreatedGroups:(NSSet *)identifiersOfNonUserCreatedGroups
{
    if ((self = [super init])) {
        _mediaSourceIdentifier = mediaSourceIdentifier;
        _mediaType = mediaType;
        _identifiersOfNonUserCreatedGroups = identifiersOfNonUserCreatedGroups;
    }
    return self;
}

@synthesize mediaSourceIdentifier = _mediaSourceIdentifier;
@synthesize mediaSource = _mediaSource;
@synthesize mediaType = _mediaType;
@synthesize identifiersOfNonUserCreatedGroups = _identifiersOfNonUserCreatedGroups;

/**
 Returns the mediaSourceIdentifier of the receiver as the bundle identifier of the library's source app.
 */
- (NSString *)sourceAppBundleIdentifier
{
    return [self mediaSourceIdentifier];
}

/**
 Returns whether group (aka node) is populated with child group objects rather than real media objects.
 @discussion This default implementation returns NO.
 */
- (BOOL)shouldUseChildGroupsAsMediaObjectsForMediaGroup:(MLMediaGroup *)mediaGroup
{
    return NO;
}

/**
 @return Type of media group provided unified across all possible media sources.
 @discussion Default return value is kIMBMLMediaGroupTypeAlbum.
 */
- (IMBMLMediaGroupType *)typeForMediaGroup:(MLMediaGroup *)mediaGroup
{
    return kIMBMLMediaGroupTypeAlbum;
}

/**
 */
- (NSImage *)thumbnailForMediaObject:(MLMediaObject *)mediaObject
{
    NSURL *url = mediaObject.thumbnailURL;
    
    [url startAccessingSecurityScopedResource];
    
    NSImage *thumbnail = [[NSImage alloc] initWithContentsOfURL:url];
    
    [url stopAccessingSecurityScopedResource];
    
    return thumbnail;
}

/**
 @return Last object in media object list of the receiver.
 */
- (MLMediaObject *)keyMediaObjectForMediaGroup:(MLMediaGroup *)mediaGroup
{
        NSArray *mediaObjects = [IMBAppleMediaLibraryPropertySynchronizer mediaObjectsForMediaGroup:mediaGroup];
        MLMediaObject *mediaObject = [mediaObjects lastObject];
    return mediaObject;
}

@end
