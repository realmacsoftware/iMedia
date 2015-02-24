//
//  IMBApplePhotosParser.h
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import <iMedia/iMedia.h>

#import "IMBAppleMediaLibraryParser.h"

/**
 Base class for parser classes that support different Apple Photos app media types.
 */
@interface IMBApplePhotosParser : IMBAppleMediaLibraryParser

@end

@interface IMBApplePhotosImageParser : IMBApplePhotosParser

@end

@interface IMBApplePhotosMovieParser : IMBApplePhotosParser

@end

