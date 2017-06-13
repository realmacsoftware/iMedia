//
//  SBUtilities.m
//  SandboxingKit
//
//  Created by Jörg Jacobsen on 2/16/12. Copyright 2012 SandboxingKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// Author: Peter Baumgartner, Jörg Jacobsen


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "SBUtilities.h"
#import <Security/SecCode.h>
#import <Security/SecRequirement.h>
#import <sys/types.h>
#import <pwd.h>
#import <XPCKit/XPCKit.h>

//----------------------------------------------------------------------------------------------------------------------

/**
 An experimental switch to boost performance but definitly not ready for prime time
 */
#define ALWAYS_COPY_OBJECTS_ON_PERFORM_SELECTOR_ASYNC 1

/**
 We would prefer the more comfortable NSOperationQueue over dispatch_async()/dispatch_semaphore_... but it
 turns out that requesting a root media group in the context of the AppleMediaLibraryParser takes about
 twice as long compared to dispatch_async() and thus accounts for the vast majority of the time spent to
 "open" a an Apple Media Library framework based library.
 
 I know this sounds crazy but our measurements regarding the matter are unambiguous (as of 2017/02/07).
 
 We still keep the alternate NSOperationQueue implementation for future use in case our observations render no longer relevant.
 */
#define USE_DISPATCH_ASYNC_INSTEAD_OF_OP_QUEUE 1

/**
 The maximum number of concurrent execution of requests to performSelectorAsync()
 
 @Discussion
 We had instances where the Facebook parser hung up on us when about 60 some parallel requests were issued
 (this might correlate with the fact that all Facebook requests reach out to the internet).
 
 Going beyond eight parallel resources does not seem to gain any better performance on any of the parsers.
 */
const NSInteger kMaximumPerformAsyncConcurrency = 8;


#pragma mark
#pragma mark Sandbox Check


// Check if the host app is sandboxed. This code is based on suggestions from the FrameworksIT mailing list...

BOOL SBIsSandboxed()
{
	static BOOL sIsSandboxed = NO;
	static dispatch_once_t sIsSandboxedToken = 0;

    dispatch_once(&sIsSandboxedToken,
    ^{
		if (NSAppKitVersionNumber >= 1138) // Are we running on Lion?
		{
			SecCodeRef codeRef = NULL;
			SecCodeCopySelf(kSecCSDefaultFlags,&codeRef);

			if (codeRef != NULL)
			{
				SecRequirementRef reqRef = NULL;
				SecRequirementCreateWithString(CFSTR("entitlement[\"com.apple.security.app-sandbox\"] exists"),kSecCSDefaultFlags,&reqRef);

				if (reqRef != NULL)
				{
					OSStatus status = SecCodeCheckValidity(codeRef,kSecCSDefaultFlags,reqRef);
					
					if (status == noErr)
					{
						sIsSandboxed = YES;
					};
                    CFRelease(reqRef);
				}
                CFRelease(codeRef);
			}
		}
    });
	
	return sIsSandboxed;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Directory Access


// Replacement function for NSHomeDirectory...

NSString* SBHomeDirectory()
{
	struct passwd* passInfo = getpwuid(getuid());
	char* homeDir = passInfo->pw_dir;
	return [NSString stringWithUTF8String:homeDir];
}


// Convenience function for getting a path to an application container directory...

NSString* SBApplicationContainerHomeDirectory(NSString* inBundleIdentifier)
{
    NSString* bundleIdentifier = inBundleIdentifier;
    
    if (bundleIdentifier == nil) 
    {
        bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    NSString* appContainerDir = SBHomeDirectory();
    appContainerDir = [appContainerDir stringByAppendingPathComponent:@"Library"];
    appContainerDir = [appContainerDir stringByAppendingPathComponent:@"Containers"];
    appContainerDir = [appContainerDir stringByAppendingPathComponent:bundleIdentifier];
    appContainerDir = [appContainerDir stringByAppendingPathComponent:@"Data"];
    
    return appContainerDir;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Preferences Access


// Private function to read contents of a prefs file at given path into a dinctionary...

static NSDictionary* _SBPreferencesDictionary(NSString* inHomeFolderPath,NSString* inPrefsFileName)
{
    NSString* path = [inHomeFolderPath stringByAppendingPathComponent:@"Library"];
    path = [path stringByAppendingPathComponent:@"Preferences"];
    path = [path stringByAppendingPathComponent:inPrefsFileName];
    path = [path stringByAppendingPathExtension:@"plist"];
    
   return [NSDictionary dictionaryWithContentsOfFile:path];
}


// Private function to access a certain value in the prefs dictionary...

static CFTypeRef _SBCopyValue(NSDictionary* inPrefsFileContents,CFStringRef inKey)
{
    CFTypeRef value = NULL;

    if (inPrefsFileContents) 
    {
        id tmp = [inPrefsFileContents objectForKey:(NSString*)inKey];
    
        if (tmp)
        {
            value = (CFTypeRef) tmp;
            CFRetain(value);
        }
    }
    
    return value;
}


// High level function that should be used instead of CFPreferencesCopyAppValue, because in  
// sandboxed apps we need to work around problems of CFPreferencesCopyAppValue returning NULL...

CFTypeRef SBPreferencesCopyAppValue(CFStringRef inKey,CFStringRef inBundleIdentifier)
{
    CFTypeRef value = NULL;
    NSString* path;
    
    // First try the official API. If we get a value, then use it...
    
    if (value == nil)
    {
        value = CFPreferencesCopyAppValue((CFStringRef)inKey,(CFStringRef)inBundleIdentifier);
    }
    
    // In sandboxed apps that may have failed tough, so try a workaround. If the app has the entitlement
    // com.apple.security.temporary-exception.files.absolute-path.read-only for a wide enough part of the
    // file system, we can read the prefs file ourself and parse it manually...
    
    if (value == nil)
    {
        path = SBHomeDirectory();
        NSDictionary* prefsFileContents = _SBPreferencesDictionary(path,(NSString*)inBundleIdentifier);
        value = _SBCopyValue(prefsFileContents,inKey);
    }

    // It's possible that the other app is sandboxed as well, so we may need look for the prefs file 
    // in its container directory...
    
    if (value == nil)
    {
        path = SBApplicationContainerHomeDirectory((NSString*)inBundleIdentifier);
        NSDictionary* prefsFileContents = _SBPreferencesDictionary(path,(NSString*)inBundleIdentifier);
        value = _SBCopyValue(prefsFileContents,inKey);
    }
    
    return value;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark XPC Abstraction


//----------------------------------------------------------------------------------------------------------------------

#if USE_DISPATCH_ASYNC_INSTEAD_OF_OP_QUEUE

/**
 Returns a serial queue.
 
 @see SBPerformSelectorAsync().
 */
dispatch_queue_t _SBSerialTargetDispatchQueue()
{
    static dispatch_queue_t sSharedInstance = NULL;
    static dispatch_once_t sOnceToken = 0;
    
    dispatch_once(&sOnceToken,
                  ^{
                      sSharedInstance = dispatch_queue_create("com.sandboxingkit.sbutilities", NULL);
                  });
    
    return sSharedInstance;
    
}

/**
 Returns a dispatch semaphore limited to a maximum number of jobs, intended to restrain parallelity when dispatching events with GCD
 
 @see kMaximumPerformAsyncConcurrency
 */
dispatch_semaphore_t _SBDispatchSemaphore()
{
    static dispatch_semaphore_t sSharedInstance = NULL;
    static dispatch_once_t sOnceToken = 0;
    
    dispatch_once(&sOnceToken,
                  ^{
                      sSharedInstance = dispatch_semaphore_create(kMaximumPerformAsyncConcurrency);
                  });
    
    return sSharedInstance;
}

#else

/**
 Returns an NSOperationQueue limited to a maximum number of jobs, intended to restrain parallelity when dispatching events with GCD
 
 @see kMaximumPerformAsyncConcurrency
 */
NSOperationQueue* _SBConstrainedTargetOperationQueue()
{
	static NSOperationQueue* sSharedInstance = NULL;
	static dispatch_once_t sOnceToken = 0;
    
    dispatch_once(&sOnceToken,
                  ^{
                     sSharedInstance = [[NSOperationQueue alloc] init];
                     [sSharedInstance setMaxConcurrentOperationCount:kMaximumPerformAsyncConcurrency];
                  });
    
 	return sSharedInstance;
    
}

#endif

// Dispatch a message with optional argument object to a target object asynchronously. When connnection (which must
// be an XPCConnection) is supplied the message will be transferred to an XPC service for execution. Please note  
// that inTarget and inObject must conform to NSCoding for this to work, or they cannot be sent across the connection. 
// When connection is nil (e.g. running on Snow Leopard) message will be dispatched asynchronously via GCD, but the 
// behaviour will be similar...

void SBPerformSelectorAsync(id inConnection,id inTarget,SEL inSelector,id inObject, dispatch_queue_t returnHandlerQueue, SBReturnValueHandler inReturnHandler)
{
    // If we have an XPC connection, then send a request to perform selector on target to our XPC
    // service and hand the results to the supplied return handler block...
    
    if (inConnection && [inConnection respondsToSelector:@selector(sendSelector:withTarget:object:returnValueHandler:)])
    {
        [inConnection setReplyDispatchQueue:returnHandlerQueue];
        SBReturnValueHandler returnHandler = [inReturnHandler copy];
        
        [inConnection sendSelector:inSelector
                        withTarget:inTarget
                            object:inObject
                returnValueHandler:
         ^(id object, NSError* inError)
         {
             // Avoid direct propagation of technical XPC errors to app
             
             if ([[inError domain] isEqualToString:kXPCKitErrorDomain])
             {
                 NSString* title = NSLocalizedStringWithDefaultValue(@"SB.XPCError.requestFailed", @"SandboxingKit", IMBBundle(), @"Media Browser Error", @"Error title");
                 NSString* description = NSLocalizedStringWithDefaultValue(@"SB.XPCError.couldNotComplete", @"SandboxingKit", IMBBundle(), @"The last operation could not be completed. It is possible that some media files are not displayed correctly.", @"Error description");
                 
                 NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                                       title,@"title",
                                       description,NSLocalizedDescriptionKey,
                                       nil];
                 
                 inError = [NSError errorWithDomain:kSandboxingKitErrorDomain
                                               code:kSandboxingKitErrorCouldNotComplete
                                           userInfo:info];
             }
             returnHandler(object, inError);
             [returnHandler release];
         }];
    }
    
    // Otherwise we'll just do the work directly (but asynchronously) via GCD queues.
    // Once again the result is handed over to the return handler block. Please note that we are
	// copying inTarget and inObject so they are dispatched under same premises as XPC (XPC uses archiving)...
   
    else
    {
#if ALWAYS_COPY_OBJECTS_ON_PERFORM_SELECTOR_ASYNC
        id targetCopy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:inTarget]];
        id objectCopy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:inObject]];
#else
        id targetCopy = inTarget;
        id objectCopy = inObject;
#endif
//        NSLog(@"Asynchronous perform on target object %@", targetCopy);
//        NSLog(@"Asynchronous perform with parameter object %@", objectCopy);
        
        dispatch_retain(returnHandlerQueue);
#if USE_DISPATCH_ASYNC_INSTEAD_OF_OP_QUEUE
        // dispatch to a serial queue to get the request off the main thread so it does not block it
        // when it is waiting for a semaphore signal because the maximum number of parallel threads had been reached
        dispatch_async(_SBSerialTargetDispatchQueue(),^() {
            dispatch_semaphore_wait(_SBDispatchSemaphore(), DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^() {
                
#else
                [_SBConstrainedTargetOperationQueue() addOperationWithBlock:^() {
#endif
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    NSError* error = nil;
                    id result = nil;
                    
                    if (objectCopy)
                    {
                        result = [targetCopy performSelector:inSelector withObject:objectCopy withObject:(id)&error];
                    }
                    else
                    {
                        result = [targetCopy performSelector:inSelector withObject:(id)&error];
                    }
                    
                    // Copy the results and send them back to the caller. This provides the exact same workflow as with XPC.
                    // This is extremely useful for debugging purposes, but leads to a performance hit in non-sandboxed
                    // host apps. For this reason the following line may be commented out once our code base is stable...
                    
#if ALWAYS_COPY_OBJECTS_ON_PERFORM_SELECTOR_ASYNC
                    result = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:result]];
#endif
                    dispatch_async(returnHandlerQueue,^()
                                   {
                                       inReturnHandler(result,error);
                                       dispatch_release(returnHandlerQueue);
                                   });
                    [pool drain];
#if USE_DISPATCH_ASYNC_INSTEAD_OF_OP_QUEUE
                    dispatch_semaphore_signal(_SBDispatchSemaphore());
                });
            });
#else
            }];
#endif
    }
}


//----------------------------------------------------------------------------------------------------------------------


// Here's the same thing as an Objective-C wrapper (for those devs that do not like using pure C functions)...
 							
@implementation NSObject (SBPerformSelectorAsync)

- (void) performAsyncSelector:(SEL)inSelector withObject:(id)inObject onConnection:(id)inConnection completionHandlerQueue:(dispatch_queue_t)inQueue completionHandler:(SBReturnValueHandler)inCompletionHandler
{
	SBPerformSelectorAsync(inConnection,self,inSelector,inObject,inQueue,inCompletionHandler);
}

@end


//----------------------------------------------------------------------------------------------------------------------



