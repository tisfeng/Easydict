//
//  NSProcessInfo+XPMArgumentParser.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/15/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XPMArgumentPackage;

@interface NSProcessInfo (XPMArgumentParser)

- (XPMArgumentPackage *)xpmargs_parseArgumentsWithSignatures:(id)signatures;

@end
