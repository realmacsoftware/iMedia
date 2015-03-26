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

typedef IMBAppleMediaLibraryParserConfiguration *(^IMBMLParserConfigurationFactory)(MLMediaType);

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


@interface IMBAppleMediaLibraryParserConfiguration : NSObject <IMBAppleMediaLibraryParserDelegate>
{
    NSString *_mediaSourceIdentifier;
    MLMediaType _mediaType;
    NSSet *_identifiersOfNonUserCreatedGroups;
}

/**
 The media source identifier used in the media sources dictionary of an MLMediaLibrary.
 */
@property (nonatomic, strong) NSString *mediaSourceIdentifier;

/**
 The media type of the library.
 */
@property (nonatomic) MLMediaType mediaType;

/**
 The set of group identifiers identifying non-user created media groups.
 */
@property (nonatomic, strong) NSSet *identifiersOfNonUserCreatedGroups;

/**
 Designated initiliazer.
 */
- (instancetype)initWithMediaSourceIdentifier:(NSString *)mediaSourceIdentifier
                   AppleMediaLibraryMediaType:(MLMediaType)mediaType
            identifiersOfNonUserCreatedGroups:(NSSet *)identifiersOfNonUserCreatedGroups;

@end

