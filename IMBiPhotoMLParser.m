//
//  IMBiPhotoMLParser.m
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import "IMBiPhotoMLParser.h"

/**
 Attribute key supported by Photos media source (as of OS X 10.10.3)
 */
NSString *kIMBMediaRootGroupAttributeLibraryURL = @"URL";

@implementation IMBiPhotoMLImageParser

#pragma mark Configuration

/**
 Internal media type is specific to Apple Media Library based parsers and is not to be confused with kIMBMediaTypeImage and its siblings.
 */
+ (MLMediaType)internalMediaType
{
    return MLMediaTypeImage;
}

/**
 See implementation of this method in IMBParser for what this is about. Resist the temptation of using -classname since a class name might change over time but this identifier prefix must not!
 */
- (NSString*) iMedia2PersistentResourceIdentifierPrefix
{
    return @"IMBiPhotoMLImageParser";
}

@end

#pragma mark -

@implementation IMBiPhotoMLMovieParser

#pragma mark Configuration

/**
 Internal media type is specific to Apple Media Library based parsers and is not to be confused with kIMBMediaTypeImage and its siblings.
 */
+ (MLMediaType)internalMediaType
{
    return MLMediaTypeMovie;
}

/**
 See implementation of this method in IMBParser for what this is about. Resist the temptation of using -classname since a class name might change over time but this identifier prefix must not!
 */
- (NSString*) iMedia2PersistentResourceIdentifierPrefix
{
    return @"IMBiPhotoMLMovieParser";
}

@end

#pragma mark -

@implementation IMBiPhotoMLParser

#pragma mark Configuration

/**
 Returns the identifier for the app that is associated with sources handled by the parser.
 */
+ (NSString *)mediaSourceIdentifier
{
    return MLMediaSourceiPhotoIdentifier;
}

/**
 Returns the URL denoting the actual media source on disk. Must be subclassed.
 
 @discussion
 If the URL is not accessible to a concrete parser it may return nil but implications of doing so are not yet fully understood.
 */
- (NSURL *)mediaSourceURLForGroup:(MLMediaGroup *)mediaGroup
{
    return mediaGroup.attributes[kIMBMediaRootGroupAttributeLibraryURL];
}

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from iPhoto library representation (MLMediaObject.attributes) to iMedia representation
    
    NSDictionary *internalMetadata = inObject.preliminaryMetadata;
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionary];
    
//    // Width, height
//    
//    NSString *resolutionString = internalMetadata[@"resolutionString"];
//    if ([resolutionString isKindOfClass:[NSString class]]) {
//        NSSize size = NSSizeFromString(resolutionString);
//        externalMetadata[@"width"] = [NSString stringWithFormat:@"%d", (int)size.width];
//        externalMetadata[@"height"] = [NSString stringWithFormat:@"%d", (int)size.height];
//    }
//    
//    // Creation date and time
//    
//    id timeInterval = internalMetadata[@"DateAsTimerInterval"];
//    NSString *timeIntervalString = nil;
//    if ([timeInterval isKindOfClass:[NSNumber class]]) {
//        timeIntervalString = [((NSNumber *)timeInterval) stringValue];
//    } else if ([timeInterval isKindOfClass:[NSString class]]) {
//        timeIntervalString = timeInterval;
//    }
//    if (timeIntervalString) {
//        externalMetadata[@"dateTime"] = timeIntervalString;
//    }
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"iPhoto (Apple Media Library)";
}

@end
