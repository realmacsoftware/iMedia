//
//  IMBiTunesParserConfiguration.h
//  iMedia
//
//  Created by Jörg Jacobsen on 10.03.15.
//
//

#import "IMBAppleMediaLibraryParserConfiguration.h"

/**
 This parser configuration for iTunes is preliminary. As of 2015-03-11 Apple Media Library framework does not seem to support iTunes (anymore?). A more specific configuration of this class shouldn't be much work, though.
 */

@interface IMBiTunesParserConfiguration : IMBAppleMediaLibraryParserConfiguration <IMBAppleMediaLibraryParserDelegate>

@end
