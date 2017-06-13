//
//  FMResultSet+iMedia.m
//  iMedia
//
//  Created by Pierre Bernard on 23/03/16.
//
//

#import "FMResultSet+iMedia.h"


@implementation FMResultSet (iMedia)

- (BOOL) imb_hasColumnWithName:(NSString*)columnName {
	return ([[self columnNameToIndexMap] objectForKey:[columnName lowercaseString]]) != nil;
}

@end
