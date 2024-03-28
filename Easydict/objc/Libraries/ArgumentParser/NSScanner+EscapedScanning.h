//
//  NSScanner+EscapedScanning.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/17/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (EscapedScanning)

- (void)xpmargs_scanUpToCharacterFromSet:(NSCharacterSet *)upTo unlessPrecededByCharacterFromSet:(NSCharacterSet *)escapedBy intoString:(__autoreleasing NSString **)into;

@end
