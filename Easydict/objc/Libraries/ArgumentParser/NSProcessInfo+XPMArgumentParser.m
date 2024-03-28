//
//  NSProcessInfo+XPMArgumentParser.m
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/15/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "NSProcessInfo+XPMArgumentParser.h"

#import "XPMArgumentParser.h"

@implementation NSProcessInfo (XPMArgumentParser)

- (XPMArgumentPackage *)xpmargs_parseArgumentsWithSignatures:(id)signatures
{
    XPMArgumentParser * p = [[XPMArgumentParser alloc] initWithArguments:[self arguments] signatures:signatures];
    return [p parse];
}

@end
