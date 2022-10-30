//
//  MMMake.m
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "MMMake.h"

//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NSObject (MMMake)

+ (instancetype)mm_make:(void (NS_NOESCAPE ^)(id obj))block {
    id obj = [self new];
    block(obj);
    return obj;
}

+ (instancetype)mm_anyMake:(void (NS_NOESCAPE ^)(id obj))block {
    id obj = [self new];
    block(obj);
    return obj;
}

- (id)mm_put:(void (NS_NOESCAPE ^)(id obj))block {
    block(self);
    return self;
}

- (id)mm_anyPut:(void (NS_NOESCAPE ^)(id obj))block {
    block(self);
    return self;
}

@end

DefineCategoryMMMake_m(NSView)
DefineCategoryMMMake_m(NSButton)
DefineCategoryMMMake_m(NSTextField)
DefineCategoryMMMake_m(NSTextView)
DefineCategoryMMMake_m(NSScrollView)
DefineCategoryMMMake_m(NSImageView)

//#pragma clang diagnostic pop
