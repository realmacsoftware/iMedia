//
//  IMBiPhotoMLParserMessenger.m
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <MediaLibrary/MediaLibrary.h>

#import "IMBiPhotoMLParserMessenger.h"
#import "IMBMovieObjectViewController.h"

#pragma mark -

@implementation IMBiPhotoMLImageParserMessenger

#pragma mark Configuration

/**
 Registers the receiver with IMBParserController.
 */
+ (void) load {
    @autoreleasepool {
        [IMBParserController registerParserMessengerClass:self forMediaType:[self mediaType]];
    }
}

/**
 Returns a pointer to a dispatch_once() predicate that will be used to ensure onetime parser instances creation
 */
+ (dispatch_once_t *)parsersCreationToken {
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

+ (NSString*) mediaType {
    return kIMBMediaTypeImage;
}

+ (NSString*) identifier {
    return @"com.karelia.imedia.iPhotoML.image";
}

+ (NSString*) parserClassName {
    return @"IMBiPhotoMLImageParser";
}

#pragma mark - XPC Methods

/**
 Returns the cache of all parsers associated with iPhoto media objects of same media type.
 */
+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        parsers = [[NSMutableArray alloc] init];
    });
    return parsers;
}

@end

#pragma mark -

@implementation IMBiPhotoMLMovieParserMessenger

#pragma mark Configuration

/**
 Registers the receiver with IMBParserController.
 */
+ (void) load {
    @autoreleasepool {
        [IMBParserController registerParserMessengerClass:self forMediaType:[self mediaType]];
    }
}

/**
 Returns a pointer to a dispatch_once() predicate that will be used to ensure onetime parser instances creation
 */
+ (dispatch_once_t *)parsersCreationToken {
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

+ (NSString*) mediaType {
    return kIMBMediaTypeMovie;
}

+ (NSString*) identifier {
    return @"com.karelia.imedia.iPhotoML.movie";
}

+ (NSString*) parserClassName {
    return @"IMBiPhotoMLMovieParser";
}

#pragma mark - XPC Methods

/**
 Returns the cache of all parsers associated with iPhoto media objects of same media type.
 */
+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        parsers = [[NSMutableArray alloc] init];
    });
    return parsers;
}

#pragma mark - Object description

+ (NSString*) objectCountFormatSingular {
    return [IMBMovieObjectViewController objectCountFormatSingular];
}

+ (NSString*) objectCountFormatPlural {
    return [IMBMovieObjectViewController objectCountFormatPlural];
}

@end

#pragma mark -

@implementation IMBiPhotoMLParserMessenger

/**
 Returns the identifier for the app that is associated with sources handled by the parser. Must be subclassed.
 */
+ (NSString *)sourceAppBundleIdentifier
{
    return MLMediaSourceiPhotoIdentifier;
}


+ (NSString*) xpcServiceIdentifierPostfix
{
    return @"iPhotoML";
}

@end
