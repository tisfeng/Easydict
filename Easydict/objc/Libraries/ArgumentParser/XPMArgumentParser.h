//
//  XPMArgumentParser.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/23/12.
//  Copyright (c) 2012, 2016 Christopher Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XPMArgumentPackage;

@interface XPMArgumentParser : NSObject

- (id)initWithArguments:(NSArray *)arguments signatures:(id)signatures;
- (XPMArgumentPackage *)parse;

@end
