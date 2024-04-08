//
//  XPMArgumentParser.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/23/12.
//  Copyright (c) 2012, 2016 Christopher Miller. All rights reserved.
//

#import "XPMArgumentParser.h"
#import "XPMMutableAttributedArray.h"
#import "NSArray+XPMArgumentsNormalizer.h"
#import "XPMArguments_Coalescer_Internal.h"
#import "XPMArgsKonstants.h"

#import "XPMArgumentPackage.h"
#import "XPMArgumentPackage_Private.h"

#import "XPMArgumentSignature.h"
#import "XPMCountedArgument.h"
#import "XPMValuedArgument.h"

@interface XPMArgumentParser () {
	XPMMutableAttributedArray * _arguments;
	NSMutableSet * _signatures;
	NSMutableDictionary * _switches;
	NSMutableDictionary * _aliases;
	XPMArgumentPackage * _package;
}

- (void)injectSignatures:(NSSet *)signatures;
- (void)performSignature:(XPMArgumentSignature *)signature fromIndex:(NSUInteger)index;
- (NSRange)rangeOfValuesStartingFromIndex:(NSUInteger)index tryFor:(NSRange)wantedArguments;

@end

@implementation XPMArgumentParser

- (id)initWithArguments:(NSArray *)arguments signatures:(id)signatures
{
	self = [super init];
	
	if (self) {
		_arguments = [arguments xpmargs_normalize];
		_signatures = [xpmargs_coalesceToSet(signatures) mutableCopy];
		_switches = [[NSMutableDictionary alloc] init];
		_aliases = [[NSMutableDictionary alloc] init];
		_package = [[XPMArgumentPackage alloc] init];
		[self injectSignatures:_signatures];
	}
	
	return self;
}

- (XPMArgumentPackage *)parse
{
	for (NSUInteger i = 0; i < [_arguments count]; ++i) {
		NSString * v = [_arguments objectAtIndex:i];
		XPMArgumentSignature * signature;
		NSString * type = [_arguments valueOfAttribute:xpmargs_typeKey forObjectAtIndex:i];
		
		if ([type isEqual:xpmargs_switch]) { // switch
			
			NSString * switchKey = [v stringByReplacingOccurrencesOfString:@"-" withString:@""];
			
			if ((signature = [_switches objectForKey:switchKey]) != nil) {
				[self performSignature:signature fromIndex:i];
			} else {
				[_package->unknownSwitches addObject:v];
			}
			
		} else if ([type isEqual:xpmargs_value]) {

			if ([_arguments booleanValueOfAttribute:xpmargs_isValueCaptured forObjectAtIndex:i]) {
				continue;
			} else {
				// it's an uncaptured value, which is really quite rare. The only way to pre-mark a value to with an equals-sign, which means that an equals sign assignment was used on a signature which doesn't capture values.
				// find a way to associate this with what it wanted to be associated with in a weak way.
				[_package->uncapturedValues addObject:v];
			}
			
		} else if ([type isEqual:xpmargs_unknown]) {
			
			if ([_arguments booleanValueOfAttribute:xpmargs_isValueCaptured forObjectAtIndex:i]) {
				continue;
			} else {
				// potentially uncaptured value, or else it could be an alias
				if ((signature = [_aliases objectForKey:v]) != nil) {
					[self performSignature:signature fromIndex:i];
				} else {
					// it's an uncaptured value, not strongly associated with anything else
					// it could be weakly associated with something, however
					[_package->uncapturedValues addObject:v];
				}
			}
		} else if ([type isEqualToString:xpmargs_barrier]) {
			// skip the barrier
		} else {
			NSLog(@"Unknown type: %@", type);
		}
	}
	
	return _package;
}

/**
 * Inject a whole mess of signatures into the parser state.
 */
- (void)injectSignatures:(NSSet *)signatures
{
	[signatures enumerateObjectsUsingBlock:^(XPMArgumentSignature * signature, BOOL *stop) {
		[signature.switches enumerateObjectsUsingBlock:^(id _switch, BOOL *stop) {
			[_switches setObject:signature forKey:_switch];
		}];
		[signature.aliases enumerateObjectsUsingBlock:^(id alias, BOOL *stop) {
			[_aliases setObject:signature forKey:alias];
		}];
	}];
}

/**
 * Handle the signature.
 */
- (void)performSignature:(XPMArgumentSignature *)signature fromIndex:(NSUInteger)index
{
	// 1. is it valued?
	if ([signature isKindOfClass:[XPMValuedArgument class]]) {
		XPMValuedArgument * valuedSignature = (XPMValuedArgument *)signature;
		
		// pop forward to find possible arguments
		
		NSRange rangeOfValues = [self rangeOfValuesStartingFromIndex:index+1 tryFor:valuedSignature.valuesPerInvocation];
		NSIndexSet * indexSetOfValues = [NSIndexSet indexSetWithIndexesInRange:rangeOfValues];
		[indexSetOfValues enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			NSString * value = [_arguments objectAtIndex:idx];
			[_arguments setBooleanValue:true ofAttribute:xpmargs_isValueCaptured forObjectAtIndex:idx];
			[_package addObject:value toSignature:valuedSignature];
		}];
			
	} else {
		[_package incrementCountOfSignature:signature];
	}
	
	// 2. inject subsignatures
	[self injectSignatures:signature.injectedSignatures];
}

- (NSRange)rangeOfValuesStartingFromIndex:(NSUInteger)index tryFor:(NSRange)wantedArguments
{
	bool (^isValue)(NSMutableDictionary *) = ^(NSMutableDictionary * attributes) {
		NSString * vType = [attributes objectForKey:xpmargs_typeKey];
		return (bool)([vType isEqual:xpmargs_value] || [vType isEqual:xpmargs_unknown]);
	};
	bool (^isBarrier)(NSMutableDictionary *)= ^(NSMutableDictionary * attributes) {
		return (bool)([[attributes objectForKey:xpmargs_typeKey] isEqual:xpmargs_barrier]);
	};
	bool (^isCaptured)(NSMutableDictionary *)= ^(NSMutableDictionary * attributes){
		return (bool)([[attributes objectForKey:xpmargs_isValueCaptured] boolValue] == YES);
	};
	
	NSRange retVal={0,0};
	retVal.location = [_arguments indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [_arguments count] - index)] options:0 passingTest:^bool(id obj, NSMutableDictionary *attributes, NSUInteger idx, BOOL *stop) {
		if (isBarrier(attributes) && !isCaptured(attributes)) {
			[attributes setObject:[NSNumber numberWithBool:YES] forKey:xpmargs_isValueCaptured]; // capture this barrier
			*stop = YES;
			return NO;
		} else if (isValue(attributes) && !isCaptured(attributes)) {
			return YES;
		}
		
		return NO;
	}];
	
	if (retVal.location == NSNotFound) return retVal;
	
	retVal.length = [_arguments indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(retVal.location, MIN(wantedArguments.length, [_arguments count] - retVal.location))] options:0 passingTest:^bool(id obj, NSMutableDictionary *attributes, NSUInteger idx, BOOL *stop) {
		if (isValue(attributes) && !isCaptured(attributes)) return false;
		return true;
	}] - retVal.location;
	
	if (retVal.length == 0) retVal.length ++ ;
	if (retVal.length == NSNotFound - retVal.location) retVal.length = 1;
					
	return retVal;
}

@end
