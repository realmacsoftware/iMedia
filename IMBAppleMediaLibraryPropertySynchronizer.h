//
//  IMBAppleMediaLibraryPropertySynchronizer.h
//  iMedia
//
//  Created by Jörg Jacobsen on 13.02.15.
//
//

#import <Foundation/Foundation.h>
#import <MediaLibrary/MediaLibrary.h>

/**
 This class provides synchronous access to properties of certain objects of Apple's MediaLibrary framework that by design reliably return values only asynchronously through KVO ("mediaSources" and friends).
 
 Synchronous access to these properties is of great value for MediaLibrary-based iMedia parsers since parsers must return values synchronously to their client classes.
 */
@interface IMBAppleMediaLibraryPropertySynchronizer : NSObject
{
    id _observedObject;
    NSString *_key;
    id _valueForKey;
    dispatch_semaphore_t _semaphore;
}

/**
 Returns value for given key of object synchronously.
 
 Must not be called from main thread for keys like "mediaSources", "rootMediaGroup", "mediaObjects"
 since it would block main thread forever!
 */
+ (id)synchronousValueForObservableKey:(NSString *)key ofObject:(id)object;

/**
 Synchronously retrieves all media sources for mediaLibrary.
 
 This method must not be called from the main thread since it would block the main thread forever!
 */
+ (NSDictionary *)mediaSourcesForMediaLibrary:(MLMediaLibrary *)mediaLibrary;

/**
 Synchronously retrieves media root group for mediaSource.
 
 This method must not be called from the main thread since it would block the main thread forever!
 */
+ (MLMediaGroup *)rootMediaGroupForMediaSource:(MLMediaSource *)mediaSource;

/**
 Synchronously retrieves all media objects for mediaGroup.
 
 This method must not be called from the main thread since it would block the main thread forever!
 */
+ (NSArray *)mediaObjectsForMediaGroup:(MLMediaGroup *)mediaGroup;

/**
 Synchronously retrieves icon image for mediaGroup.
 
 This method must not be called from the main thread since it would block the main thread forever!
 */
+ (NSImage *)iconImageForMediaGroup:(MLMediaGroup *)mediaGroup;
@end
