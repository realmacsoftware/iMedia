//
//  IMBNavigationController.h
//  iMedia
//
//  Created by Jörg Jacobsen on 29.04.15.
//
//

#import <Foundation/Foundation.h>

@class IMBNavigationController;

@protocol IMBNavigationLocation <NSObject>

/**
 Determines whether the receiver is to be replaced by other location when other location is pushed directly on top of it.
 */
- (BOOL)replaceOnPushBy:(id)otherLocation;

@end

#pragma mark -

@protocol IMBNavigable <NSObject>

/**
 Does everything that needs to be done to establish location within the receiver.
 */
- (id<IMBNavigable>)gotoLocation:(id<IMBNavigationLocation>)location;

/**
 @return The receiver's current location.
 */
- (id<IMBNavigationLocation>)currentLocation;

@optional

/**
 Called after navigation controller reached bottom of navigation stack.
 */
- (void)didGoBackToOldestLocation;

/**
 Called after navigation controller reached top of navigation stack.
 */
- (void)didGoForwardToLatestLocation;


/**
 Called after navigation controller changed its current index into its navigation stack but neither reached bottom nor top of navigation stack.
 */
- (void)didGotoIntermediateLocation;

@end

#pragma mark -

@interface IMBNavigationController : NSObject {
    __unsafe_unretained id<IMBNavigable> _delegate;
    NSMutableArray *_navigationStack;
    NSInteger _currentIndex;
    BOOL _goingBackOrForward;
}

@property (nonatomic) BOOL goingBackOrForward;

/**
 Designated Initializer.
 */
- (instancetype)initWithDelegate:(id<IMBNavigable>)delegate;

/**
 Invokes -gotoLocation on delegate with the previous location.
 */
- (IBAction)goBackward:(id)sender;

/**
 Invokes -gotoLocation on delegate with the previous to going back location.
 */
- (IBAction)goForward:(id)sender;

/**
 Pushes a location onto the history of locations stack. Removes all forward locations.
 */
- (void)pushLocation:(id)location;

/**
 Clears the whole history of locations stack without going to any location.
 */
- (void)reset;

@end
