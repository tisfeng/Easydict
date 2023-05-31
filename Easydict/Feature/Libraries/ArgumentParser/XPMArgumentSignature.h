//
//  XPMArgumentSignature.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/22/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XPMArgumentSignature : NSObject < NSCopying >

/**
 * A switch is defined as a dash-prefixed invocation, which come in two flavors:
 *
 * 1. Flags, which are composed of a single dash, then a single non-whitespace, non-dash character. Flags may be grouped, and will grab values (for valued signatures) in the order in which they appear in the grouping.
 * 2. Banners, which are composed of two dashes, then a string. This string may not start with a dash, but may contain any non-whitespace character within it. You may not group banner arguments.
 */
@property (strong) NSSet * switches;

/**
 * An alias is defined as a string which is not preceded by any dashes, which triggers behavior in the argument parser. For example, you might assign the alias `of` as the output file argument. Thus, you could invoke that argument using the terse syntax `of=file.txt` (but not `of file.txt`), omitting any dashes.
 *
 * You should be very careful with aliases, since the definition of an alias will disqualify any input string from behaving as an argument value (assuming you want values including an equals sign).
 */
@property (strong) NSSet * aliases;

/**
 * If this argument is invoked, inject this set of argument signatures into the current parser.
 */
@property (strong) NSSet * injectedSignatures;

/**
 * If this is not nil, then this block will be called to retrieve special text given for the description of the signature. The arguments are the current signature, the indent level, and the current terminal width (if available).
 */
@property (copy) NSString * (^descriptionHelper) (XPMArgumentSignature * currentSignature, NSUInteger indentLevel, NSUInteger terminalWidth);

- (NSString *)descriptionForHelpWithIndent:(NSUInteger)indent terminalWidth:(NSUInteger)width;

/**
 * Create a new argument signature using the terse format language.
 *
 * @see initWithFormat:
 */
+ (id)argumentSignatureWithFormat:(NSString *)format, ...;

/**
 * Create a new argument signature using a terse format language, the format specifiers of which are interpreted by NSString's format specifiers.
 *
 * The format language is quite simple:
 *
 * Counted Arguments are constructed using a simple list of invocation signatures they should respond to, enclosed in brackets:
 *
 *     [-v --verbose doVerbose]
 *
 * `-v` becomes a flag switch, `--verbose` becomes a banner switch, and `doVerbose` is added to the aliases list. You'll get back an FSCountedArgument object.
 *
 * Valued arguments are slightly more complex. They use the same kind of syntax to define their switches and aliases, but also include another set of grammar, some of which is optional. The following are equivalent:
 *
 *     [-f --file]={1,1}
 *     [-f --file]=
 *
 * The equals sign indicates a valued argument, then the minimum and maximum captured values per invocation are provided with a regex-like syntax. The colon followed by a boolean statement indicates whether the invocation should grab beyond barriers. (See the documentation for FSValuedArgument).
 */
- (id)initWithFormat:(NSString *)format, ...;

+ (id)argumentSignatureWithFormat:(NSString *)format arguments:(va_list)args;
- (id)initWithFormat:(NSString *)format arguments:(va_list)args;

@end
