//
//  XPMArgumentSignature.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/22/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArgumentSignature.h"
#import "XPMArgumentSignature_Private.h"
#import "XPMArguments_Coalescer_Internal.h"
#import "NSScanner+EscapedScanning.h"

#import "XPMCountedArgument.h"
#import "XPMValuedArgument.h"

// used in computing the hash value
#import <CommonCrypto/CommonDigest.h>

void xpmargs_ScanFormatCtorHead(NSScanner * scanner, NSMutableArray<NSString *> * switches, NSMutableArray<NSString *> * aliases,  NSRange * _Nullable valueRange, BOOL * didFindRange);
void xpmargs_ScanFormatCtorTail(NSScanner * scanner, NSRange * valueRange, BOOL * didFindRange);

@implementation XPMArgumentSignature

@synthesize switches = _switches;
@synthesize aliases = _aliases;

@synthesize injectedSignatures = _injectedSignatures;
@synthesize descriptionHelper = _descriptionHelper;

- (id)initWithSwitches:(id)switches aliases:(id)aliases
{
	self = [self init];
	
	_switches = xpmargs_coalesceToSet(switches);
	_aliases = xpmargs_coalesceToSet(aliases);
	
	if (self) {
		_switches = switches?:_switches; // keep empty set
		_aliases = aliases?:_aliases; // keep empty set
	}
	
	return self;
}

- (NSString *)descriptionForHelpWithIndent:(NSUInteger)indent terminalWidth:(NSUInteger)width
{
	return @"";
}

#pragma mark Format String Constructors

+ (id)argumentSignatureWithFormat:(NSString *)format, ...
{
	va_list args;
	va_start(args, format);
	
	XPMArgumentSignature * signature = [XPMArgumentSignature argumentSignatureWithFormat:format arguments:args];
	
	va_end(args);
	
	return signature;
}

- (id)initWithFormat:(NSString *)format, ...
{
	va_list args;
	va_start(args, format);
	
	self = [self initWithFormat:format arguments:args];
	
	va_end(args);
	
	return self;
}

+ (id)argumentSignatureWithFormat:(NSString *)format arguments:(va_list)args
{
	return [[[self class] alloc] initWithFormat:format arguments:args];
}

- (id)initWithFormat:(NSString *)format arguments:(va_list)args
{
	NSString * input = [[NSString alloc] initWithFormat:format arguments:args];
	
	NSScanner * scanner = [[NSScanner alloc] initWithString:input];
	
	NSMutableArray<NSString *> * foundSwitches = [[NSMutableArray<NSString *> alloc] init];
	NSMutableArray<NSString *> * foundAliases = [[NSMutableArray<NSString *> alloc] init];
	BOOL didFindRange = NO;
	NSRange foundRange;
	
	xpmargs_ScanFormatCtorHead(scanner, foundSwitches, foundAliases, &foundRange, &didFindRange);
	
	if (didFindRange == NO) {
		self = [XPMCountedArgument countedArgumentWithSwitches:foundSwitches aliases:foundAliases];
	} else {
		self = [XPMValuedArgument valuedArgumentWithSwitches:foundSwitches aliases:foundAliases valuesPerInvocation:foundRange];
	}
	
	return self;
}

#pragma mark Private Implementation

- (void)updateHash:(CC_MD5_CTX *)md5
{
	// note that _injectedSignatures and _descriptionHelper is ignored in the uniqueness evaluation
	
	// add the class name too, just to make it more unique
	NSUInteger classHash = [NSStringFromClass([self class]) hash];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5_Update(md5, (const void *)&classHash, sizeof(NSUInteger));

#pragma clang diagnostic pop
    
	for (NSString * s in _switches) {
		NSUInteger hash = [xpmargs_expandSwitch(s) hash];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CC_MD5_Update(md5, (const void *)&hash, sizeof(NSUInteger));
#pragma clang diagnostic pop
	}
	
	for (NSString * s in _aliases) {
		NSUInteger hash = [s hash];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CC_MD5_Update(md5, (const void *)&hash, sizeof(NSUInteger));
#pragma clang diagnostic pop
	}
}

- (bool)respondsToSwitch:(NSString *)s
{
	if ([s hasPrefix:@"--"]) {
		s = [s substringFromIndex:2];
	}
	else if ([s hasPrefix:@"-"]) {
		s = [s substringFromIndex:1];
	}
	
	return (bool)[_switches containsObject:s];
}

- (bool)respondsToAlias:(NSString *)alias
{
	return (bool)[_aliases containsObject:alias];
}

#pragma mark NSCopying

- (id)copy
{
	XPMArgumentSignature * copy = [[[self class] alloc] initWithSwitches:_switches aliases:_aliases];
	
	if (copy) {
		copy->_injectedSignatures = _injectedSignatures;
	}
	
	return copy;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self copy];
}

#pragma mark NSObject

- (id)init
{
	if ([self class] == [XPMArgumentSignature class]) {
		[NSException raise:@"net.fsdev.ArgumentParser.VirtualClassInitializedException" format:@"This is supposed to be a pure-virtual class. Please use either %@ or %@ instead of directly using this class.", NSStringFromClass([XPMCountedArgument class]), NSStringFromClass([XPMValuedArgument class])];
	}
	
	self = [super init];
	
	if (self) {
		_injectedSignatures = [NSSet set];
		_switches = [NSSet set];
		_aliases = [NSSet set];
	}
	
	return self;
}

- (BOOL)isEqual:(id)object
{
	if ([object class] == [self class]) {
		return [object hash] == [self hash];
	} else {
		return NO;
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end

void xpmargs_ScanFormatCtorHead(NSScanner * scanner, NSMutableArray<NSString *> * switches, NSMutableArray<NSString *> * aliases,  NSRange * valueRange, BOOL * didFindRange) {
	NSString * sqBracket;
	[scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"["] intoString:&sqBracket];
	NSCAssert(sqBracket != nil, @"expecting '[' at opening of argument signature format string");
	sqBracket = nil;
	
	NSCharacterSet * closingBracket = [NSCharacterSet characterSetWithCharactersInString:@"]"];
	
	NSString * enclosedString;
	[scanner xpmargs_scanUpToCharacterFromSet:closingBracket unlessPrecededByCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\\"] intoString:&enclosedString];
	NSCAssert(enclosedString != nil, @"There must be some aliases in the argument signature format string");
	
	for (NSString * s in [enclosedString componentsSeparatedByString:@" "]) {
		if ([s hasPrefix:@"--"]) {
			[switches addObject:[s substringFromIndex:2]];
		} else if ([s hasPrefix:@"-"]) {
			[switches addObject:[s substringFromIndex:1]];
		} else {
			[aliases addObject:s];
		}
	}
	
	[scanner scanCharactersFromSet:closingBracket intoString:&sqBracket]; // scan the last ]
	
	xpmargs_ScanFormatCtorTail(scanner, valueRange, didFindRange);
}

void xpmargs_ScanAndAssertRightCurly(NSScanner * scanner) {
	NSString * rightCurlyBrace = nil;
	[scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"}"] intoString:&rightCurlyBrace];
	NSCAssert(rightCurlyBrace != nil, @"Cannot omit closing curly brace from argument format string");
}

void xpmargs_ScanFormatCtorTail(NSScanner * scanner, NSRange * valueRange, BOOL * didFindRange) {
	NSString * equalBit = nil;
	[scanner scanString:@"=" intoString:&equalBit];
	
	if (equalBit == nil) { // early exit if there's nothing else to scan
		return;
	}
	
	*didFindRange = YES;
	*valueRange = NSMakeRange(1, 1);
	
	NSString * leftCurlyBrace = nil;
	[scanner scanString:@"{" intoString:&leftCurlyBrace];
	
	if (leftCurlyBrace == nil) {
		return; // the {1,1} range is correct
	}
	
	*valueRange = NSMakeRange(NSNotFound, NSNotFound);
	unsigned long long temp;
	
	BOOL scanned = [scanner scanUnsignedLongLong:&temp];
	NSCAssert(scanned == true, @"Must have scanned a value");
	valueRange->location = (NSUInteger)temp;
	
	NSString * comma;
	[scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","] intoString:&comma];
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&leftCurlyBrace]; // skip whitespace, if it's there
	scanned = [scanner scanUnsignedLongLong:&temp];
	
	if (comma == nil) {
		xpmargs_ScanAndAssertRightCurly(scanner);
		valueRange->length = valueRange->location;
		return; // use the range {n,n}
	}
	
	if (scanned == false) {
		xpmargs_ScanAndAssertRightCurly(scanner);
		return; // the {n,infty} range is correct
	}
	
	valueRange->length = (NSUInteger)temp;
	return; // the {n,m} range is correct
}
