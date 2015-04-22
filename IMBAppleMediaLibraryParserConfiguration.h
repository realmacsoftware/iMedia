//
//  IMBAppleMediaLibraryParserConfiguration.h
//  iMedia
//
//  Created by Jörg Jacobsen on 06.03.15.
//
//

#import <iMedia/iMedia.h>
#import "IMBAppleMediaLibraryParser.h"

@class IMBAppleMediaLibraryParserConfiguration;

typedef id<IMBAppleMediaLibraryParserDelegate> (^IMBMLParserConfigurationFactory)(MLMediaType);

/**
 Parser configuration factory for Apple iPhoto app.
 */
extern IMBMLParserConfigurationFactory IMBMLiPhotoParserConfigurationFactory;

/**
 Parser configuration factory for Apple Aperture app.
 */
extern IMBMLParserConfigurationFactory IMBMLApertureParserConfigurationFactory;

/**
 Parser configuration factory for Apple Photos app.
 */
extern IMBMLParserConfigurationFactory IMBMLPhotosParserConfigurationFactory;

/**
 Parser configuration factory for Apple iTunes app.
 */
extern IMBMLParserConfigurationFactory IMBMLiTunesParserConfigurationFactory;


@interface IMBAppleMediaLibraryParserConfiguration : NSObject
{
    NSString *_mediaSourceIdentifier;
    MLMediaSource *_mediaSource;
    MLMediaType _mediaType;
    NSSet *_identifiersOfNonUserCreatedGroups;
}

/**
 The media source identifier used in the media sources dictionary of an MLMediaLibrary.
 */
@property (nonatomic, strong) NSString *mediaSourceIdentifier;

/**
 The media source of an MLMediaLibrary.
 */
@property (nonatomic, strong) MLMediaSource *mediaSource;

/**
 The media type of the library.
 */
@property (nonatomic) MLMediaType mediaType;

/**
 The set of group identifiers identifying non-user created media groups.
 */
@property (nonatomic, strong) NSSet *identifiersOfNonUserCreatedGroups;

/**
 Returns the mediaSourceIdentifier of the receiver as the bundle identifier of the library's source app.
 */
- (NSString *)sourceAppBundleIdentifier;

/**
 Designated initiliazer.
 */
- (instancetype)initWithMediaSourceIdentifier:(NSString *)mediaSourceIdentifier
                   AppleMediaLibraryMediaType:(MLMediaType)mediaType
            identifiersOfNonUserCreatedGroups:(NSSet *)identifiersOfNonUserCreatedGroups;

/**
 @return The string @"Album"
 */
- (IMBMLMediaGroupType *)typeForMediaGroup:(MLMediaGroup *)mediaGroup;

/**
 @return Last object in media object list of the receiver.
 */
- (MLMediaObject *)keyMediaObjectForMediaGroup:(MLMediaGroup *)mediaGroup;

/**
 */
- (NSImage *)thumbnailForMediaObject:(MLMediaObject *)mediaObject;

/**
 @discussion
 Must add return value of super implementation if overriden.
 */
- (NSDictionary *)metadataForMediaObject:(MLMediaObject *)mediaObject;

/**
 */
- (NSString *)countFormatForGroup: (MLMediaGroup *)mediaGroup plural:(BOOL)plural;

@end

