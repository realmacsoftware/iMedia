//
//  IMBAppleMediaLibraryParser.h
//  iMedia
//
//  Created by Jörg Jacobsen on 24.02.15.
//
//

#import <MediaLibrary/MediaLibrary.h>
#import <iMedia/iMedia.h>

#import "IMBParser.h"

@protocol IMBAppleMediaLibraryParserDelegate <NSObject>

/**
 Returns the identifier for the app that is associated with sources handled by the parser. Must be subclassed.
 
 @see MLMediaLibrary media source identifiers
 */
- (NSString *)mediaSourceIdentifier;

/**
 Internal media type is specific to Apple Media Library based parsers and not to be confused with kIMBMediaTypeImage and its siblings.
 */
- (MLMediaType)mediaType;

/**
 Returns the identifier for the app that is associated with sources handled by the parser.
 */
- (NSString *)sourceAppBundleIdentifier;

/**
 Returns a set of group identifiers identifying all groups that were automatically created by the app that owns the media library.
 */
- (NSSet *)identifiersOfNonUserCreatedGroups;

/**
 Returns whether a node is populated with node objects rather than media objects when node is not a leaf node.
 */
- (BOOL)shouldPopulateNodesWithNodeObjects;

@optional

/**
 The name of the library used for display.
 @discussion Default is the localized bundle name of the source app.
 @see sourceAppBundleIdentifier
 */
- (NSString *)libraryName;

/**
 Returns the URL denoting the actual media source on disk.
 
 @discussion
 If the URL is not accessible to a concrete parser it may return nil but implications of doing so are not yet fully understood.
 */
- (NSURL *)mediaSourceURLForGroup:(MLMediaGroup *)mediaGroup;

/**
 Returns a dictionary of metadata for inObject.
 @discussion Keys must conform to what's used in -...
 */
- (NSDictionary *)metadataForObject:(IMBObject *)inObject error:(NSError *__autoreleasing *)outError;

/**
 Returns whether a media group should be displayed or not. Default is YES.
 */
- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup;

/**
 Returns whether a media group should reuse the media objects of its parent group or not. Default is No.
 @discussion Reusing media objects may result in substantial performance increase when populating a node.
 */
- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup;

/**
 */
- (MLMediaObject *)keyMediaObjectForMediaGroup:(MLMediaGroup *)mediaGroup fromMediaSource:(MLMediaSource *)mediaSource;
@end

/**
 Base class for parser classes that access their libraries through Apple's MediaLibrary framework. May be used as is. Must be configured through delegate.
 */
@interface IMBAppleMediaLibraryParser : IMBParser
{
    MLMediaLibrary *_AppleMediaLibrary;
    MLMediaSource *_AppleMediaSource;
    id<IMBAppleMediaLibraryParserDelegate> _configuration;
}

/**
 The root library object (providing possibly multiple media sources from different apps).
 */
@property (strong) MLMediaLibrary *AppleMediaLibrary;

/**
 An MLMediaSource (an app's library) in Apple speak is not a mediaSource (a library's URL) in iMedia speak.
 */
@property (strong) MLMediaSource *AppleMediaSource;

@property (strong) id<IMBAppleMediaLibraryParserDelegate> configuration;

/**
 Converts from IMB media type to Apple Media Library media type.
 */
+ (MLMediaType)MLMediaTypeForIMBMediaType:(NSString *)mediaType;

/**
 Returns whether the node given should be shown in the node hierarchy.
 
 @discussion
 This implementation always returns YES. You are welcome to override in your subclass parser.
 */

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup;

/**
 Returns whether the group given should use the same media objects as its parent.
 
 @discussion
 This implementation always returns NO. You are welcome to override in your subclass parser (will boost performance).
 */
- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup;

@end
