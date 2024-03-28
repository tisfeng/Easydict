//
//  XPMArgumentPackage.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 2/23/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

//! dumb return structure which bundles up all the relevant information
@interface XPMArgumentPackage : NSObject

- (NSArray *)allObjectsForSignature:(id)signature;
- (id)firstObjectForSignature:(id)signature;
- (id)lastObjectForSignature:(id)signature;
- (id)objectAtIndex:(NSUInteger)index forSignature:(id)signature;

- (bool)booleanValueForSignature:(id)signature;
- (NSUInteger)countOfSignature:(id)signature;

- (NSArray *)unknownSwitches;
- (NSArray *)uncapturedValues;

@end
