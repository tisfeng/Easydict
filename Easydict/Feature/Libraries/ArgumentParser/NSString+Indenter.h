//
//  NSString+Indenter.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/11/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Indenter)

- (NSMutableString *)xpmargs_mutableStringByIndentingToWidth:(NSUInteger)indent lineLength:(NSUInteger)width;

@end
