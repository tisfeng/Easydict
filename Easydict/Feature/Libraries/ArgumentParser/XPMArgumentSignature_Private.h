//
//  XPMArgumentSignature_Private.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/14/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArgumentSignature.h"

// used in computing the hash value
#import <CommonCrypto/CommonDigest.h>

NSRegularExpression * xpmargs_generalRegex(NSError **);

@interface XPMArgumentSignature () {
@protected
    NSSet * _switches;
    NSSet * _aliases;
    NSSet * _injectedSignatures;
    NSString * (^_descriptionHelper) (XPMArgumentSignature * currentSignature, NSUInteger indentLevel, NSUInteger terminalWidth);
}

- (id)initWithSwitches:(id)switches aliases:(id)aliases;

- (void)updateHash:(CC_MD5_CTX *)md5; // update the hash value with shared bits

- (bool)respondsToSwitch:(NSString *)s;
- (bool)respondsToAlias:(NSString *)alias;

@end
