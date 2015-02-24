//
//  IMBApplePhotosParserMessenger.h
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import <iMedia/iMedia.h>

#import "IMBAppleMediaLibraryParserMessenger.h"

/**
 Base class for messenger classes that support different Apple Photos app media types.
 */
@interface IMBApplePhotosParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBApplePhotosImageParserMessenger : IMBApplePhotosParserMessenger

@end

@interface IMBApplePhotosMovieParserMessenger : IMBApplePhotosParserMessenger

@end
