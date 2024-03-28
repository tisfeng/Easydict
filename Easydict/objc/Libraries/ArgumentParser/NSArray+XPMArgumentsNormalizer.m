//
//  NSArray+XPMArgumentsNormalizer.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/15/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "NSArray+XPMArgumentsNormalizer.h"
#import "XPMMutableAttributedArray.h"
#import "XPMArgsKonstants.h"

@implementation NSArray (XPMArgumentsNormalizer)

- (XPMMutableAttributedArray *)xpmargs_normalize
{
	XPMMutableAttributedArray * args = [XPMMutableAttributedArray attributedArrayWithCapacity:[self count]];
	[self enumerateObjectsUsingBlock:^(NSString * arg, NSUInteger idx, BOOL *stop) {
		if (![arg isKindOfClass:[NSString class]]) {
			return;
		} // just... what?
		
		// handle equals-sign assignments
		// possibly check for \= so that we can escape from = assignments. probably overkill though
		NSRange r = [arg rangeOfString:@"="];
		NSString * value = nil;
		
		if (r.location != NSNotFound) {
			value = [arg substringFromIndex:r.location+r.length];
			arg = [arg substringToIndex:r.location];
		}
		
		// long form switch
		if ([arg hasPrefix:@"--"]) {
			if ([arg length] == 2) {
				[args addObject:[NSNull null] withAttributes:[NSDictionary dictionaryWithObject:xpmargs_barrier forKey:xpmargs_typeKey]];
			} else {
				[args addObject:arg withAttributes:[NSDictionary dictionaryWithObject:xpmargs_switch forKey:xpmargs_typeKey]];
			}
		} else if ([arg hasPrefix:@"-"]) { // condensed switches
			for (NSUInteger i = 1; i < [arg length]; ++i) {
				unichar c = [arg characterAtIndex:i];
				[args addObject:[NSString stringWithFormat:@"-%c", c] withAttributes:[NSDictionary dictionaryWithObject:xpmargs_switch forKey:xpmargs_typeKey]];
			}
		} else {
			[args addObject:arg withAttributes:[NSDictionary dictionaryWithObject:xpmargs_unknown forKey:xpmargs_typeKey]];
		}
		
		if (value) { // if we had a value from and equals sign, then it's obviously an explicitly assigned value.
			[args addObject:value withAttributes:[NSDictionary dictionaryWithObject:xpmargs_value forKey:xpmargs_typeKey]];
		}
	}];
	return args;
}

@end
