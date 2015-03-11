//
//  IMBAppleMediaLibraryParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 06.03.15.
//
//

#import "IMBAppleMediaLibraryParserConfiguration.h"

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
@synthesize mediaType = _mediaType;
@synthesize identifiersOfNonUserCreatedGroups = _identifiersOfNonUserCreatedGroups;

/**
 Returns the mediaSourceIdentifier of the receiver as the bundle identifier of the library's source app.
 */
- (NSString *)sourceAppBundleIdentifier
{
    return [self mediaSourceIdentifier];
}

@end
