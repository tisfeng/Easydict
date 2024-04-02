//
//  NSScanner+EscapedScanning.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/17/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "NSScanner+EscapedScanning.h"

@implementation NSScanner (EscapedScanning)

- (void)xpmargs_scanUpToCharacterFromSet:(NSCharacterSet *)upTo unlessPrecededByCharacterFromSet:(NSCharacterSet *)escapedBy intoString:(__autoreleasing NSString **)into
{
	NSMutableString * retVal = [NSMutableString string];
	while (true) {
		NSString * s;
		[self scanUpToCharactersFromSet:upTo intoString:&s];
		if (s) {
			[retVal appendString:s];
		}
		
		if ([escapedBy characterIsMember:[[self string] characterAtIndex:[self scanLocation]-1]]) {
			// pop the last character from retVal
			[retVal deleteCharactersInRange:NSMakeRange([retVal length]-1, 1)];
			// add the next character
			[retVal appendFormat:@"%c", [[self string] characterAtIndex:[self scanLocation]]];
			// advance the scan location by 1
			[self setScanLocation:[self scanLocation]+1];
		} else {
			break;
		}
	}
	
	*into = [retVal copy];
}

@end
