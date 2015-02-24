//
//  IMBiPhotoMLParser.h
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <iMedia/iMedia.h>

#import "IMBAppleMediaLibraryParser.h"

/**
 Base class for parser classes that support different Apple iPhoto app media types.
 */
@interface IMBiPhotoMLParser : IMBAppleMediaLibraryParser

@end

@interface IMBiPhotoMLImageParser : IMBiPhotoMLParser

@end

@interface IMBiPhotoMLMovieParser : IMBiPhotoMLParser

@end
