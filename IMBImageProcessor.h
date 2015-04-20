//
//  IMBImageProcessor.h
//  iMedia
//
//  Created by Jörg Jacobsen on 16.04.15.
//
//

#import <Foundation/Foundation.h>

@interface IMBImageProcessor : NSObject

+ (instancetype)sharedInstance;

/**
 Returns a trimmed, squared image from the image given.
 @parameter cornerRadius a value between 0 and 255 denoting the percentage of rounding corners (0 = no unrounded, 255 = circle)
 */
- (CGImageRef)CGImageSquaredWithCornerRadius:(CGFloat)cornerRadius fromImage:(CGImageRef)imageRef;

/**
 Returns a trimmed, squared image from the image given.
 @parameter cornerRadius a value between 0 and 255 denoting the percentage of rounding corners (0 = no unrounded, 255 = circle)
 */
- (NSImage *)imageSquaredWithCornerRadius:(CGFloat)cornerRadius fromImage:(NSImage *)image;

/**
 @parameter cornerRadius a value between 0 and 255 denoting the percentage of rounding corners (0 = no unrounded, 255 = circle)
 */
- (NSImage *)imageMosaicFromImages:(NSArray *)images withBackgroundImage:(NSImage *)backgroundImage withCornerRadius:(CGFloat)cornerRadius;
@end
