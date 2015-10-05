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
#import "IMBFaceObjectViewController.h"

NSString *kIMBMetadataObjectCountDescriptionKey = @"ObjectCountDescription";

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

@implementation IMBAppleMediaLibraryParserMessenger

#pragma mark Configuration

/**
 initializes all subclass configurations.
 */
+ (void)load
{
    static NSMutableDictionary *subclassConfigurations;
    subclassConfigurations = [NSMutableDictionary dictionary];
}

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

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return 0;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    [self imb_throwAbstractBaseClassExceptionForSelector:_cmd];
    return nil;
}

- (NSArray *)parserInstancesWithError:(NSError **)outError
{
    Class myClass = [self class];
    dispatch_once([myClass parserInstancesOnceTokenRef], ^
                  {
                      // JJ/FIXME: Better encapsulate parser initialization in designated initializer of parser
                      IMBAppleMediaLibraryParser *parser = (IMBAppleMediaLibraryParser *)[self newParser];
                      MLMediaType mediaType = [IMBAppleMediaLibraryParser MLMediaTypeForIMBMediaType:[myClass mediaType]];
                      parser.configuration = [myClass parserConfigurationFactory](mediaType);
                      [parser initializeMediaLibrary];
                      [parser.configuration setMediaSource:parser.AppleMediaSource];
                      [[myClass parsers] addObject:parser];
                  });
    return [myClass parsers];
}


#pragma mark - Object Description

/**
 */
- (NSString*) metadataDescriptionForMetadata:(NSDictionary*)inMetadata
{
    // Node objects have other metadata than media objects
    
    NSString *metadataDescription = @"";
    NSString *objectCountDescription = inMetadata[kIMBMetadataObjectCountDescriptionKey];
    
    if (objectCountDescription != nil)		// Event, face, ...
    {
        metadataDescription = objectCountDescription;
    } else {
        // Presumably an image
        metadataDescription = [NSImage imb_imageMetadataDescriptionForMetadata:inMetadata];
    }
    return metadataDescription;
}

///**
// */
//- (NSString*) _countableMetadataDescriptionForMetadata:(NSDictionary*)inMetadata
//{
//    NSMutableString* metaDesc = [NSMutableString string];
//    
//    NSNumber* count = [inMetadata objectForKey:kIMBMediaGroupAttributeObjectMediaCount];
//    if (count)
//    {
//        NSString* formatString = [count intValue] > 1 ?
//        [[self class] objectCountFormatPlural] :
//        [[self class] objectCountFormatSingular];
//        
//        [metaDesc appendFormat:formatString, [count intValue]];
//    }
//    
////    NSNumber* dateAsTimerInterval = [inMetadata objectForKey:@"RollDateAsTimerInterval"];
////    if (dateAsTimerInterval)
////    {
////        [metaDesc imb_appendNewline];
////        NSDate* eventDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[dateAsTimerInterval doubleValue]];
////        
////        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
////        [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
////        [formatter setDateStyle:NSDateFormatterMediumStyle];	// medium date
////        
////        [metaDesc appendFormat:@"%@", [formatter stringFromDate:eventDate]];
////        
////        [formatter release];
////    }
//    return metaDesc;
//}

#pragma mark - Custom View Controller Support

//- (NSViewController*) customObjectViewControllerForNode:(IMBNode*)inNode
//{
//    IMBMLMediaGroupType *nodeType = inNode.attributes[@"type"];
//    
//    // Use custom view for events / faces
//    
//    if ([nodeType isEqualToString:kIMBMLMediaGroupTypeEventsFolder]) {
//        return[[IMBAppleMediaLibraryEventObjectViewController alloc] initForNode:inNode];
//    } else if ([nodeType isEqualToString:kIMBMLMediaGroupTypeFacesFolder]) {
//        return[[IMBFaceObjectViewController alloc] initForNode:inNode];
//    }
//    return [super customObjectViewControllerForNode:inNode];
//}

@end

#pragma mark - Subclasses For Media Type IMAGE

@implementation IMBMLPhotosImageParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnYosemite10103OrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeImage;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.Photos.image";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLPhotosParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

@implementation IMBMLiPhotoImageParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnMavericksOrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeImage;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.iPhoto.image";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLiPhotoParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

@implementation IMBMLApertureImageParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnMavericksOrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeImage;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.Aperture.image";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLApertureParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

#pragma mark - Subclasses For Media Type MOVIE

@implementation IMBMLPhotosMovieParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnYosemite10103OrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeMovie;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.Photos.movie";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLPhotosParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

@implementation IMBMLiPhotoMovieParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnMavericksOrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeMovie;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.iPhoto.movie";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLiPhotoParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

@implementation IMBMLApertureMovieParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnMavericksOrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeMovie;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.Aperture.movie";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLApertureParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end

#pragma mark - Subclasses For Media Type AUDIO

@implementation IMBMLiTunesAudioParserMessenger

+ (void) load {
    @autoreleasepool {
        if (IMBRunningOnMavericksOrNewer()) {
            [IMBParserController registerParserMessengerClass:self forMediaType:[[self class] mediaType]];
        }
    }
}

+ (NSString*) mediaType {
    return kIMBMediaTypeAudio;
}

+ (NSString*) identifier {
    return @"com.apple.medialibrary.iTunes.audio";
}

+ (NSMutableArray *)parsers
{
    static NSMutableArray *parsers = nil;
    if (!parsers) parsers = [[NSMutableArray alloc] init];
    return parsers;
}

+ (IMBMLParserConfigurationFactory)parserConfigurationFactory
{
    return IMBMLiTunesParserConfigurationFactory;
}

+ (dispatch_once_t *)parserInstancesOnceTokenRef
{
    static dispatch_once_t onceToken = 0;
    return &onceToken;
}

@end




