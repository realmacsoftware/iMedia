//
//  MLMediaGroup+iMedia.h
//  iMedia
//
//  Created by Jörg Jacobsen on 18.04.15.
//
//

#import <MediaLibrary/MediaLibrary.h>

@interface MLMediaGroup (iMedia)

/**
 */
- (NSArray *)imb_childGroupsUptoMaxCount:(NSUInteger)maxCount;

/**
 @return The number of mediaObjects of the receiver
 */
- (NSNumber *)imb_mediaObjectCount;
@end
