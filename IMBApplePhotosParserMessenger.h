//
//  IMBApplePhotosParserMessenger.h
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import <MediaLibrary/MediaLibrary.h>
#import <iMedia/iMedia.h>

/**
 Base class for messenger classes that support different Apple Photos app media types.
 */
@interface IMBApplePhotosParserMessenger : IMBParserMessenger

@end

@interface IMBApplePhotosImageParserMessenger : IMBApplePhotosParserMessenger

@end

@interface IMBApplePhotosMovieParserMessenger : IMBApplePhotosParserMessenger

@end
