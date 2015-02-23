//
//  IMBApplePhotosParserMessenger.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.02.15.
//
//

#import "NSObject+iMedia.h"
#import "NSWorkspace+iMedia.h"
#import "IMBApplePhotosParserMessenger.h"
#import "IMBApplePhotosParser.h"
#import "NSImage+iMedia.h"
#import "IMBMovieObjectViewController.h"
#import "IMBAppleMediaLibraryPropertySynchronizer.h"


#pragma mark -

@implementation IMBApplePhotosImageParserMessenger

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
    return @"com.karelia.imedia.ApplePhotos.image";
}

+ (NSString*) parserClassName {
    return @"IMBApplePhotosImageParser";
}

#pragma mark - XPC Methods

/**
 Returns the cache of all parsers associated with Photos media objects of same media type.
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

@implementation IMBApplePhotosMovieParserMessenger

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
    return @"com.karelia.imedia.ApplePhotos.movie";
}

+ (NSString*) parserClassName {
    return @"IMBApplePhotosMovieParser";
}

#pragma mark - XPC Methods

/**
 Returns the cache of all parsers associated with Photos media objects of same media type.
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

@implementation IMBApplePhotosParserMessenger

#pragma mark Configuration

/**
 Controls whether parser runs in-process or in XPC service if corresponding XPC service is present.
 
 The Apple Photos parser is not intended to run as an XPC service since it delegates all substantial work to the MLMediaLibrary service anyway. In fact it might not work in XPC service since retrieval of some of MLMediaLibrary properties is done asynchronously with KVO notifications into the main thread which might not work in XPC services.
 */
+ (BOOL) useXPCServiceWhenPresent
{
    return NO;
}

// Returns the bundle identifier of iPhoto

+ (NSString *) bundleIdentifier
{
    return @"com.apple.Photos";
}


+ (NSString*) xpcServiceIdentifierPostfix
{
    return @"ApplePhotos";
}

#pragma mark - To Be Subclassed

/**
 Returns a pointer to a dispatch_once() predicate that will be used to ensure onetime parser cache creation. Predicate must be static. Must be subclassed.
 */
+ (dispatch_once_t *)parserCacheCreationToken
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return 0;
}

/**
 Returns a pointer to a dispatch_once() predicate that will be used to ensure onetime parser instances creation. Predicate must be static. Must be subclassed.
 */
+ (dispatch_once_t *)parsersCreationToken
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return 0;
}


#pragma mark - Object Lifecycle

/**
 
 */
- (id) initWithCoder:(NSCoder *)inDecoder
{
    NSKeyedUnarchiver* decoder = (NSKeyedUnarchiver*)inDecoder;
    
    if ((self = [super initWithCoder:decoder]))
    {
        // Add handling of class specific properties / ivars here
    }
    return self;
}

/**
 
 */
- (void) encodeWithCoder:(NSCoder *)inCoder
{
    [super encodeWithCoder:inCoder];
    
    // Add handling of class specific properties / ivars here
}


/**
 
 */
- (id) copyWithZone:(NSZone*)inZone
{
    IMBApplePhotosParserMessenger* copy = [super copyWithZone:inZone];

    // Add handling of class specific properties / ivars here

    return copy;
}


#pragma mark - XPC Methods

/**
 @discussion
 A single Apple Photos parser accessing the Photos "System Library" is created and cached per Apple Photos parser messenger. Thus, access to "non system" Photos libraries is not supported. This is a restriction of the MLMediaLibrary framework. Note that you can set the Photos "System Library" in the preference pane of Photos.
 */
- (NSArray *)parserInstancesWithError:(NSError **)outError
{
    Class myClass = [self class];
    NSMutableArray *parsers = [myClass parsers];
    dispatch_once([myClass parsersCreationToken], ^{
        IMBApplePhotosParser *parser = (IMBApplePhotosParser *)[self newParser];
        parser.identifier = [myClass identifier];
        parser.mediaType = self.mediaType;
        parser.appPath = [myClass appPath];
        
        [parsers addObject:parser];
    });
    return parsers;
}

#pragma mark - Object Description

- (NSString *) metadataDescriptionForMetadata:(NSDictionary*)inMetadata
{
    return [NSImage imb_imageMetadataDescriptionForMetadata:inMetadata];
}

#pragma mark - Utility

/**
 Returns path to Photos app bundle.
 */
+ (NSString*) appPath
{
    return [[NSWorkspace imb_threadSafeWorkspace] absolutePathForAppBundleWithIdentifier:[self bundleIdentifier]];
}


@end
