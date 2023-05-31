//
//  XPMArguments_Coalescer_Internal.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/11/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArguments_Coalescer_Internal.h"

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsstring(NSString *);
NSCharacterSet * xpmargs_coalesceToCharacterSet_nsarray(NSArray *);
NSCharacterSet * xpmargs_coalesceToCharacterSet_nsset(NSSet *);
NSCharacterSet * xpmargs_coalesceToCharacterSet_nsorderedset(NSOrderedSet *);
NSCharacterSet * xpmargs_coalesceToCharacterSet_nsobject(NSObject *);

NSCharacterSet * xpmargs_coalesceToCharacterSet(id o) {
	if (o==nil) {
		return nil;
	} else if ([o isKindOfClass:[NSString class]]) {
		return xpmargs_coalesceToCharacterSet_nsstring(o);
	} else if ([o isKindOfClass:[NSArray class]]) {
		return xpmargs_coalesceToCharacterSet_nsarray(o);
	} else if ([o isKindOfClass:[NSSet class]]) {
		return xpmargs_coalesceToCharacterSet_nsset(o);
	} else if ([o isKindOfClass:[NSOrderedSet class]]) {
		return xpmargs_coalesceToCharacterSet_nsorderedset(o);
	} else {
	  return xpmargs_coalesceToCharacterSet_nsobject(o);
	}
}

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsstring(NSString * s) {
	return [NSCharacterSet characterSetWithCharactersInString:s];
}

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsarray(NSArray * a) {
	NSMutableCharacterSet * s = [[NSMutableCharacterSet alloc] init];
	[a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[s formUnionWithCharacterSet:xpmargs_coalesceToCharacterSet(obj)];
	}];
	return s;
}

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsset(NSSet * s) {
	NSMutableCharacterSet * cs = [[NSMutableCharacterSet alloc] init];
	[s enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		[cs formUnionWithCharacterSet:xpmargs_coalesceToCharacterSet(obj)];
	}];
	return cs;
}

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsorderedset(NSOrderedSet * s) {
	NSMutableCharacterSet * cs = [[NSMutableCharacterSet alloc] init];
	[s enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[cs formUnionWithCharacterSet:xpmargs_coalesceToCharacterSet(obj)];
	}];
	return cs;
}

NSCharacterSet * xpmargs_coalesceToCharacterSet_nsobject(NSObject * o) {
	return xpmargs_coalesceToCharacterSet_nsstring([o description]);
}

NSArray * xpmargs_coalesceToArray(id o) {
	if (!o) {
		return nil;
	} else if ([o isKindOfClass:[NSArray class]]) {
		return o;
	} else if ([o isKindOfClass:[NSString class]]) {
		return [NSArray arrayWithObject:o];
	} else if ([o isKindOfClass:[NSSet class]]||[o isKindOfClass:[NSOrderedSet class]]) {
		return [o allObjects];
	} else {
		return [NSArray arrayWithObject:[o description]];
	}
}

NSSet * xpmargs_coalesceToSet(id o) {
	if (!o) {
		return nil;
	} else if ([o isKindOfClass:[NSArray class]]) {
		return [NSSet setWithArray:o];
	} else if ([o isKindOfClass:[NSString class]]) {
		return [NSSet setWithObject:o];
	} else if ([o isKindOfClass:[NSSet class]]) {
		return o;
	} else if ([o isKindOfClass:[NSOrderedSet class]]) {
		return [(NSOrderedSet *)o set];
	} else {
		return [NSSet setWithObject:o];
	}
}

NSArray * xpmargs_charactersFromCharacterSetAsArray(NSCharacterSet * characterSet) {
	NSMutableArray * a = [NSMutableArray array];
	
	for (unichar c = 0; c < 256; ++c) {
		if ([characterSet characterIsMember:c]) {
			[a addObject:[NSString stringWithFormat:@"%c", c]];
		}
	}
	
	return [a copy];
}

NSString * xpmargs_charactersFromCharacterSetAsString(NSCharacterSet * characterSet) {
	NSMutableString * s = [NSMutableString stringWithCapacity:10];
	
	for (unichar c = 0; c < 256; ++c) {
		if ([characterSet characterIsMember:c]) {
			[s appendFormat:@"%c", c];
		}
	}
	
	return [s copy];
}

NSString * xpmargs_expandSwitch(NSString * s)
{
	if ([s length] == 1) {
		return [NSString stringWithFormat:@"-%@", s];
	} else {
		return [NSString stringWithFormat:@"--%@", s];
	}
}

NSArray * xpmargs_expandAllSwitches(id switches)
{
	NSMutableArray * a = [NSMutableArray arrayWithCapacity:[switches count]];
	
	for (NSString * s in switches) {
		[a addObject:xpmargs_expandSwitch(s)];
	}
	
	return [a copy];
}
