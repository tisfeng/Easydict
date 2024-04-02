//
//  NSArray+XPMArgumentsNormalizer.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/15/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XPMMutableAttributedArray.h"

@interface NSArray (XPMArgumentsNormalizer)

- (XPMMutableAttributedArray *)xpmargs_normalize;

@end
