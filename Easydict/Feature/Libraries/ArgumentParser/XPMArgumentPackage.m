//
//  XPMArgumentPackage.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/23/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArgumentPackage.h"
#import "XPMArgumentPackage_Private.h"

#import "XPMArgumentSignature.h"
#import "XPMArgumentSignature_Private.h"
#import "XPMCountedArgument.h"
#import "XPMValuedArgument.h"

NSString * xpmargs_expect_valuedSig = @"Please don't ask for values from an unvalued argument signature.";
NSString * xpmargs_expect_countedSig = @"Please don't ask for counts from a valued argument signature.";

/*
	CFMutableDictionaryRef countedValues;
	NSMutableDictionary * valuedValues;
	NSMutableArray * uncapturedValues;
	NSMutableSet * allSignatures;
*/

@interface XPMArgumentPackage ()
- (XPMArgumentSignature *)signatureForObject:(id)o;
- (XPMArgumentSignature *)signatureForSwitch:(NSString *)s;
- (XPMArgumentSignature *)signatureForAlias:(NSString *)alias;
@end

@implementation XPMArgumentPackage

- (NSArray *)allObjectsForSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	
	if (signature) {
		NSAssert([signature isKindOfClass:[XPMValuedArgument class]], xpmargs_expect_valuedSig);
		return [valuedValues objectForKey:signature];
	}
	
	return nil;
}

- (id)firstObjectForSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	
	if (signature) {
		NSAssert([signature isKindOfClass:[XPMValuedArgument class]], xpmargs_expect_valuedSig);
		NSMutableArray * values = [valuedValues objectForKey:signature];
		
		if (values) {
			return [values objectAtIndex:0];
		}
	}
	
	return nil;
}

- (id)lastObjectForSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	if (signature) {
		NSAssert([signature isKindOfClass:[XPMValuedArgument class]], xpmargs_expect_valuedSig);
		NSMutableArray * values = [valuedValues objectForKey:signature];
		
		if (values) {
			return [values lastObject];
		}
	}
	
	return nil;
}

- (id)objectAtIndex:(NSUInteger)index forSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	
	if (signature) {
		NSAssert([signature isKindOfClass:[XPMValuedArgument class]], xpmargs_expect_valuedSig);
		NSMutableArray * values = [valuedValues objectForKey:signature];
		
		if (values) {
			return [values objectAtIndex:index];
		}
	}
	
	return nil;
}

- (bool)booleanValueForSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	
	if (signature) {
		NSAssert([signature isKindOfClass:[XPMCountedArgument class]], xpmargs_expect_countedSig);
		
		if (CFDictionaryContainsKey(countedValues, (__bridge const void *)signature)) {
			size_t * value = (size_t *)CFDictionaryGetValue(countedValues, (__bridge const void *)signature);
			return value[0] > 0;
		}
	}
	
	return false;
}

- (NSUInteger)countOfSignature:(id)signature
{
	signature = [self signatureForObject:signature];
	
	if (signature) {
		
		if ([signature isKindOfClass:[XPMCountedArgument class]]) {
			
			if (CFDictionaryContainsKey(countedValues, (__bridge const void *)signature)) {
				size_t * value = (size_t *)CFDictionaryGetValue(countedValues, (__bridge const void *)signature);
				return value[0];
			}
			
			return 0;
			
		} else if ([signature isKindOfClass:[XPMValuedArgument class]]) {
			NSMutableArray * values = [valuedValues objectForKey:signature];
			
			if (values) {
				return [values count];
			}
			
			return 0;
		}
		
		NSAssert(true==false, @"Dude, third eye?");
	}
	
	return NSNotFound;
}

- (NSArray *)unknownSwitches
{
	return unknownSwitches;
}

- (NSArray *)uncapturedValues
{
	return uncapturedValues;
}

- (void)incrementCountOfSignature:(XPMArgumentSignature *)signature
{
	NSAssert([signature isKindOfClass:[XPMCountedArgument class]], xpmargs_expect_countedSig);
	[allSignatures addObject:signature];
	size_t * value;
	
	if (CFDictionaryContainsKey(countedValues, (__bridge const void *)signature)) {
		value = (size_t *)CFDictionaryGetValue(countedValues, (__bridge const void *)signature);
		value[0]++;
	} else {
		value = malloc(sizeof(size_t) * 1);
		value[0] = 1;
	}
	
	CFDictionarySetValue(countedValues, (__bridge const void *)signature, (const void *)value);
}

- (void)addObject:(id)object toSignature:(XPMArgumentSignature *)signature
{
	NSAssert([signature isKindOfClass:[XPMValuedArgument class]], xpmargs_expect_valuedSig);
	[allSignatures addObject:signature];
	NSMutableArray * values = [valuedValues objectForKey:signature];
	
	if (values) {
		[values addObject:object];
	} else {
		[valuedValues setObject:[NSMutableArray arrayWithObject:object] forKey:signature];
	}
}

- (XPMArgumentSignature *)signatureForObject:(id)o
{
	if ([o isKindOfClass:[XPMArgumentSignature class]]) {
		return o;
	} else if ([o isKindOfClass:[NSString class]]) {
		NSString * s = o;
		
		if ([s hasPrefix:@"-"]) {
			return [self signatureForSwitch:s];
		}
		
		return [self signatureForAlias:s];
	}
	
	return nil;
}

- (XPMArgumentSignature *)signatureForSwitch:(NSString *)s
{
	for (XPMArgumentSignature * signature in allSignatures) {
		if ([signature respondsToSwitch:s]) {
			return signature;
		}
	}
	
	return nil;
}

- (XPMArgumentSignature *)signatureForAlias:(NSString *)alias
{
	for (XPMArgumentSignature * signature in allSignatures) {
		if ([signature respondsToAlias:alias]) {
			return signature;
		}
	}
	
	return nil;
}

- (NSString *)prettyDescription
{
	NSMutableDictionary * countedDict = [NSMutableDictionary dictionaryWithCapacity:CFDictionaryGetCount(countedValues)];
	
	for (XPMArgumentSignature * s in allSignatures) {
		if (CFDictionaryContainsKey(countedValues, (__bridge const void *)s)) {
			NSUInteger v = [self countOfSignature:s];
			[countedDict setObject:[NSNumber numberWithUnsignedInteger:v] forKey:s];
		}
	}
	
	return [[NSDictionary dictionaryWithObjectsAndKeys:
					 countedDict, @"countedValues",
					 valuedValues, @"valuedValues",
					 uncapturedValues, @"uncapturedValues",
					 [allSignatures allObjects], @"allSignatures", // get around stupid Foundation description bs. (only dicts and arrays get pretty print).
					 unknownSwitches, @"unknownSwitches", nil] description];
}

#pragma mark NSObject

- (id)init
{
	self = [super init];
	
	if (self) {
		countedValues = CFDictionaryCreateMutable(NULL, 0, /*nocopy*/ &kCFTypeDictionaryKeyCallBacks, /*perform no retain/release on values*/ NULL);
		valuedValues = [[NSMutableDictionary alloc] init];
		uncapturedValues = [[NSMutableArray alloc] init];
		allSignatures = [[NSMutableSet alloc] init];
		unknownSwitches = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	CFRelease(countedValues);
}

@end
