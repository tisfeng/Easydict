//
//  XPMValuedArgument.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/11/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMValuedArgument.h"
#import "XPMArgumentSignature_Private.h"
#import "XPMArguments_Coalescer_Internal.h"
#import "NSString+Indenter.h"

// used in computing the hash value
#import <CommonCrypto/CommonDigest.h>

@implementation XPMValuedArgument

@synthesize valuesPerInvocation = _valuesPerInvocation;

+ (id)valuedArgumentWithSwitches:(id)switches aliases:(id)aliases
{
	return [[self alloc] initWithSwitches:switches aliases:aliases];
}

- (id)initWithSwitches:(id)switches aliases:(id)aliases
{
	return [super initWithSwitches:switches aliases:aliases];
}

+ (id)valuedArgumentWithSwitches:(id)switches aliases:(id)aliases valuesPerInvocation:(NSRange)valuesPerInvocation
{
	return [[self alloc] initWithSwitches:switches aliases:aliases valuesPerInvocation:valuesPerInvocation];
}

- (id)initWithSwitches:(id)switches aliases:(id)aliases valuesPerInvocation:(NSRange)valuesPerInvocation
{
	self = [super initWithSwitches:switches aliases:aliases];
	
	if (self) {
		_valuesPerInvocation = valuesPerInvocation;
	}
	
	return self;
}


#pragma mark XPMArgumentSignature

- (NSString *)descriptionForHelpWithIndent:(NSUInteger)indent terminalWidth:(NSUInteger)width
{
	if (self.descriptionHelper) {
		return self.descriptionHelper(self, indent, width);
	}
	
	if (width < 20) {
		width = 20; // just make sure
	}
    
	NSMutableArray * invocations = [NSMutableArray arrayWithCapacity:[_switches count] + [_aliases count]];
	[invocations addObjectsFromArray:xpmargs_expandAllSwitches(_switches)];
	[invocations addObjectsFromArray:[_aliases allObjects]];
	
	NSString * unmangled = [NSString stringWithFormat:@"[%@]={%lu,%lu}", [invocations componentsJoinedByString:@" "], _valuesPerInvocation.location, _valuesPerInvocation.length];
	
	NSMutableString * s = [unmangled xpmargs_mutableStringByIndentingToWidth:indent*2 lineLength:width];
	
	for (XPMArgumentSignature * signature in _injectedSignatures) {
		[s appendString:[signature descriptionForHelpWithIndent:indent+1 terminalWidth:width]];
	}
	
	NSRange last_character = NSMakeRange([s length]-1, 1);
	if ([[s substringWithRange:last_character] isEqualToString:@"\n"]) {
		[s deleteCharactersInRange:last_character];
	}
	
	return [s copy];
}

#pragma mark NSCopying

- (id)copy
{
	XPMValuedArgument * copy = [super copy];
	
	if (copy) {
		copy->_valuesPerInvocation = _valuesPerInvocation;
	}
	
	return copy;
}

#pragma mark NSObject

- (id)init
{
	self = [super init];
	
	if (self) {
		_valuesPerInvocation = NSMakeRange(1, 1);
	}
	
	return self;
}

- (NSUInteger)hash
{
	// use an MD5 hash to determine the uniqueness of the counted argument.
	// Injected sub-arguments are not considered.
	CC_MD5_CTX md5;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5_Init(&md5);
#pragma clang diagnostic pop

	[super updateHash:&md5];
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5_Update(&md5, (const void *)&_valuesPerInvocation, sizeof(NSUInteger));
#pragma clang diagnostic pop
	
	unsigned char md5_final[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5_Final(md5_final, &md5);
#pragma clang diagnostic pop
	return *((NSUInteger *)md5_final);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p switches:[%@] aliases:[%@] valuesPerInvocation:%@>", NSStringFromClass([self class]), self, [xpmargs_expandAllSwitches(_switches) componentsJoinedByString:@" "], [[_aliases allObjects] componentsJoinedByString:@" "], NSStringFromRange(_valuesPerInvocation)];
}

@end
