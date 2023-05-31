//
//  XPMArgumentPackage_Private.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/16/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArgumentPackage.h"

@class XPMArgumentSignature;

@interface XPMArgumentPackage () {
@public
    CFMutableDictionaryRef countedValues;
    NSMutableDictionary * valuedValues;
    NSMutableArray * uncapturedValues;
    NSMutableSet * allSignatures;
    NSMutableArray * unknownSwitches;
}

- (void)incrementCountOfSignature:(XPMArgumentSignature *)signature;
- (void)addObject:(id)object toSignature:(XPMArgumentSignature *)signature;
- (NSString *)prettyDescription;

@end
