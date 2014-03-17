//
//  iMedia_Tests.m
//  iMedia Tests
//
//  Created by Jörg Jacobsen on 20.11.13.
//
//

#import <XCTest/XCTest.h>
#import <iMedia/iMedia.h>
#import <iMedia/IMBiPhotoParserMessenger.h>
#import <iMedia/IMBiPhotoParserMessenger.h>
#import <iMedia/SBUtilities.h>

@interface iMedia_Tests : XCTestCase

@end

@implementation IMBiPhotoParserMessenger (Test)

- (id)returnObject:(id)object
{
    return object;
}

@end

@implementation iMedia_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 Test dispatching to XPC service or GCD.
 @discussion
 This test was introduced specifically for testing dispatching to GCD. There were reports of exceptions
 being thrown in conjunction with the keyed archiver explicitly being used.
 This method tries to reproduce the symptom. It does not enforce any assertions by itself
 */
- (void)testSBPerformSelectorAsync
{
    IMBParserMessenger *parserMessenger = [[IMBiPhotoParserMessenger alloc] init];
    IMBNode *node = [[IMBNode alloc] init];
    NSArray *objects = [NSArray arrayWithObjects:
                        [[IMBObject alloc] init],
                        [[IMBObject alloc] init],
                        [[IMBObject alloc] init],
                        nil];
    node.objects = objects;
    
    
    for (int i=1; i<=500000; i++) {
        SBPerformSelectorAsync(nil,
                               parserMessenger, @selector(returnObject:), node,
                               dispatch_get_main_queue(),
                               ^(id object, NSError *error)
                               {
                                   NSLog(@"Return handler says hello to: %@", object);
                               });
    }
}

@end
