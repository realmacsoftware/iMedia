//
//  IMBiPhotoMLParserMessenger.h
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <Cocoa/Cocoa.h>

#import "IMBAppleMediaLibraryParserMessenger.h"

/**
 Base class for messenger classes that support different Apple iPhoto app media types.
 */
@interface IMBiPhotoMLParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBiPhotoMLImageParserMessenger : IMBiPhotoMLParserMessenger

@end

@interface IMBiPhotoMLMovieParserMessenger : IMBiPhotoMLParserMessenger

@end
