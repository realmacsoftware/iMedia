//
//  IMBAppleMediaLibraryParserMessenger.m
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <MediaLibrary/MediaLibrary.h>

#import "NSObject+iMedia.h"
#import "NSWorkspace+iMedia.h"
#import "NSImage+iMedia.h"
#import "IMBAppleMediaLibraryParserMessenger.h"
#import "IMBAppleMediaLibraryParser.h"
#import "IMBAppleMediaLibraryParserConfiguration.h"

/**
 Reverse-engineered keys of the Photos app media source's attributes.
 
 Apple doesn't seem to yet publicly define these constants anywhere.
 */
NSString *kIMBMediaSourceAttributeIdentifier = @"mediaSourceIdentifier";

/**
 Attribute keys supported by iPhoto media source (as of OS X 10.10.3)
 */
NSString *kIMBMediaRootGroupAttributeLibraryURL = @"URL";

#pragma mark -

@implementation IMBAppleMediaLibraryImageParserMessenger

/**
 Registers the receiver with IMBParserController.
 */
+ (void) load {
    @autoreleasepool {
        // Apple Media Library framework public since OS X 10.9
        if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) {
            [IMBParserController registerParserMessengerClass:self forMediaType:kIMBMediaTypeImage];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeImage;
}

+ (NSString*) identifier {
    return @"com.karelia.imedia.AppleMediaLibrary.image";
}

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

- (NSArray *)parserInstancesWithError:(NSError **)outError
{
    Class myClass = [self class];
    NSMutableArray *parsers = [myClass parsers];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        [@[IMBMLiPhotoParserConfigurationFactory, IMBMLPhotosParserConfigurationFactory] enumerateObjectsUsingBlock:
         ^(IMBMLParserConfigurationFactory parserConfigurationFactory, NSUInteger idx, BOOL *stop)
         {
             IMBAppleMediaLibraryParser *parser = (IMBAppleMediaLibraryParser *)[self newParser];
             parser.configuration = parserConfigurationFactory(MLMediaTypeImage);
             [parsers addObject:parser];
         }];
    });
    return parsers;
}

@end

#pragma mark -

@implementation IMBAppleMediaLibraryMovieParserMessenger

/**
 Registers the receiver with IMBParserController.
 */
+ (void) load {
    @autoreleasepool {
        // Apple Media Library framework public since OS X 10.9
        if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) {
            [IMBParserController registerParserMessengerClass:self forMediaType:kIMBMediaTypeMovie];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeMovie;
}

+ (NSString*) identifier {
    return @"com.karelia.imedia.AppleMediaLibrary.movie";
}

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

- (NSArray *)parserInstancesWithError:(NSError **)outError
{
    Class myClass = [self class];
    NSMutableArray *parsers = [myClass parsers];
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^
                  {
                      [@[IMBMLiPhotoParserConfigurationFactory,
                         IMBMLPhotosParserConfigurationFactory] enumerateObjectsUsingBlock:
                       ^(IMBMLParserConfigurationFactory parserConfigurationFactory, NSUInteger idx, BOOL *stop)
                       {
                           IMBAppleMediaLibraryParser *parser = (IMBAppleMediaLibraryParser *)[self newParser];
                           parser.configuration = parserConfigurationFactory(MLMediaTypeMovie);
                           [parsers addObject:parser];
                       }];
                  });
    return parsers;
}

@end

#pragma mark -

@implementation IMBAppleMediaLibraryAudioParserMessenger

/**
 Registers the receiver with IMBParserController.
 */
+ (void) load {
    @autoreleasepool {
        // Apple Media Library framework public since OS X 10.9
        if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) {
            [IMBParserController registerParserMessengerClass:self forMediaType:kIMBMediaTypeAudio];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeAudio;
}

+ (NSString*) identifier {
    return @"com.karelia.imedia.AppleMediaLibrary.audio";
}

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

- (NSArray *)parserInstancesWithError:(NSError **)outError
{
    Class myClass = [self class];
    NSMutableArray *parsers = [myClass parsers];
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^
                  {
                      [@[IMBMLiTunesParserConfigurationFactory] enumerateObjectsUsingBlock:
                       ^(IMBMLParserConfigurationFactory parserConfigurationFactory, NSUInteger idx, BOOL *stop)
                       {
                           IMBAppleMediaLibraryParser *parser = (IMBAppleMediaLibraryParser *)[self newParser];
                           parser.configuration = parserConfigurationFactory(MLMediaTypeAudio);
                           [parsers addObject:parser];
                       }];
                  });
    return parsers;
}

@end

#pragma mark -

@implementation IMBAppleMediaLibraryParserMessenger

#pragma mark Configuration

/**
 Controls whether parser runs in-process or in XPC service if corresponding XPC service is present.
 
 The Apple Photos parser is not intended to run as an XPC service since it delegates all substantial work to the MLMediaLibrary service anyway. In fact it might not work in XPC service since retrieval of some of MLMediaLibrary properties is done asynchronously with KVO notifications into the main thread which might not work in XPC services.
 */
+ (BOOL) useXPCServiceWhenPresent
{
    return NO;
}

+ (NSString *)parserClassName
{
    return @"IMBAppleMediaLibraryParser";
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
    id copy = [super copyWithZone:inZone];
    
    // Add handling of class specific properties / ivars here
    
    return copy;
}



#pragma mark - Object Description

- (NSString *) metadataDescriptionForMetadata:(NSDictionary*)inMetadata
{
    return [NSImage imb_imageMetadataDescriptionForMetadata:inMetadata];
}

@end
