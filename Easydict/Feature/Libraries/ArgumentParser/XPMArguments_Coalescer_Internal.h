//
//  XPMArguments_Coalescer_Internal.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/11/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

NSCharacterSet *	xpmargs_coalesceToCharacterSet(id);
NSArray *					xpmargs_coalesceToArray(id);
NSSet *						xpmargs_coalesceToSet(id);
NSArray *					xpmargs_charactersFromCharacterSetAsArray(NSCharacterSet *);
NSString *				xpmargs_charactersFromCharacterSetAsString(NSCharacterSet *);
NSString *				xpmargs_expandSwitch(NSString *); // expand a switch, taking c to -c and config to --config
NSArray *					xpmargs_expandAllSwitches(id);
