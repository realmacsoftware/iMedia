//
//  IMBAppleMediaLibraryParserMessenger.h
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <iMedia/iMedia.h>

extern NSString *kIMBMetadataObjectCountDescriptionKey;

@interface IMBAppleMediaLibraryParserMessenger : IMBParserMessenger

@end

#pragma mark - Media Type IMAGE

@interface IMBMLPhotosImageParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBMLiPhotoImageParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBMLApertureImageParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

#pragma mark - Media Type MOVIE

@interface IMBMLPhotosMovieParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBMLiPhotoMovieParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

@interface IMBMLApertureMovieParserMessenger : IMBAppleMediaLibraryParserMessenger

@end

#pragma mark - Media Type AUDIO

@interface IMBMLiTunesAudioParserMessenger : IMBAppleMediaLibraryParserMessenger

@end
