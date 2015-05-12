//
//  IMBNavigationController.m
//  iMedia
//
//  Created by Jörg Jacobsen on 29.04.15.
//
//

#import "IMBNavigationController.h"

@interface IMBNavigationController ()

@property (nonatomic, strong) NSMutableArray *navigationStack;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) id<IMBNavigationLocation> currentLocation;
@property (nonatomic, unsafe_unretained) IBOutlet id<IMBNavigable> delegate;

@end

@implementation IMBNavigationController

#pragma mark - Accessors

@synthesize navigationStack = _navigationStack;
@synthesize currentIndex = _currentIndex;
@synthesize delegate = _delegate;
@synthesize goingBackOrForward = _goingBackOrForward;

- (id<IMBNavigationLocation>)currentLocation
{
    return [self validIndex:self.currentIndex] ? self.navigationStack[self.currentIndex] : nil;
}

- (void)setCurrentLocation:(id<IMBNavigationLocation>)currentLocation
{
    if ([self validIndex:self.currentIndex]) {
        self.navigationStack[self.currentIndex] = currentLocation;
    }
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
    return [self initWithDelegate:nil];
}

/**
 Designated Initializer.
 */
- (instancetype)initWithDelegate:(id<IMBNavigable>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.navigationStack = [NSMutableArray array];
        [self reset];
    }
    return self;
}

#pragma mark - Navigation

- (void)pushLocation:(id<IMBNavigationLocation>)location
{
    // If current index is not top of stack we must pop locations above
    // But never pop any location when going backward or forward
    
    if (!self.goingBackOrForward) {
        [self.navigationStack removeObjectsInRange:[self rangeToTopOfNavigation]];
    }
    
    if ([self.currentLocation replaceOnPushBy:location]) {
        self.currentLocation = location;
    } else {
        [self.navigationStack addObject:location];
        self.currentIndex = [self.navigationStack count] - 1;   // Always point to last object after push
    }

    if (self.currentIndex >= 0 && [self.delegate respondsToSelector:@selector(didGoForwardToLatestLocation)]) {
        [self.delegate didGoForwardToLatestLocation];
    };
    NSLog(@"%@", self);
}

- (void)goBackward
{
    self.goingBackOrForward = YES;
    
    // current location may have changed. Push it (which will result in: replace it
    // if -replaceOnPushBy is correctly implemented by the actual location class)
    
    [self pushLocation:[self.delegate currentLocation]];
    
    NSInteger proposedIndex = self.currentIndex - 1;
    if ([self validIndex:proposedIndex]) {
        id location = self.navigationStack[proposedIndex];
        
        if (location) {
            [self.delegate gotoLocation:location];
            self.currentIndex = proposedIndex;
        }
        if (self.currentIndex == 0 && [self.delegate respondsToSelector:@selector(didGoBackToOldestLocation)]) {
            [self.delegate didGoBackToOldestLocation];
        } else if ( [self.delegate respondsToSelector:@selector(didGotoIntermediateLocation)]) {
            [self.delegate didGotoIntermediateLocation];
        }
    }
    self.goingBackOrForward = NO;
    NSLog(@"%@", self);
}

- (void)goForward
{
    self.goingBackOrForward = YES;
    
    // current location may have changed. Push it (which will result in: replace it
    // if -replaceOnPushBy is correctly implemented by the actual location class)
    
    [self pushLocation:[self.delegate currentLocation]];
    
    NSInteger proposedIndex = self.currentIndex + 1;
    if ([self validIndex:proposedIndex]) {
        id location = self.navigationStack[proposedIndex];
        
        if (location) {
            [self.delegate gotoLocation:location];
            self.currentIndex = proposedIndex;
        }
        if ([self atTopOfNavigation] && [self.delegate respondsToSelector:@selector(didGoForwardToLatestLocation)]) {
            [self.delegate didGoForwardToLatestLocation];
        } else if ( [self.delegate respondsToSelector:@selector(didGotoIntermediateLocation)]) {
            [self.delegate didGotoIntermediateLocation];
        }
    }
    self.goingBackOrForward = NO;
    NSLog(@"%@", self);
}

#pragma mark - Actions

- (IBAction)goBackward:(id)sender
{
    [self goBackward];
}

- (IBAction)goForward:(id)sender
{
    [self goForward];
}

#pragma mark - Helper

- (BOOL)validIndex:(NSInteger)index
{
    return index < [self.navigationStack count] && index >= 0;
}

- (NSRange)rangeToTopOfNavigation
{
    return NSMakeRange(self.currentIndex+1, [self.navigationStack count] - (self.currentIndex+1));
}

- (BOOL)atTopOfNavigation
{
    return (self.currentIndex == [self.navigationStack count] - 1);
}

- (void)reset
{
    [self.navigationStack removeAllObjects];
    self.currentIndex = -1;
    self.goingBackOrForward = NO;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *description = @"\n";
    
    for (NSInteger index = 0; index < [self.navigationStack count]; index++) {
        NSString *rowPrefix = nil;
        if (index == self.currentIndex) {
            rowPrefix = @"-->";
        } else {
            rowPrefix = @"   ";
        }
        description = [NSString stringWithFormat:@"%@%@ %@\n", description, rowPrefix, [self.navigationStack[index] description]];
    }
    return description;
}
@end
