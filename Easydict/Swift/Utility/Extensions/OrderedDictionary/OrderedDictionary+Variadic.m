//
//  OrderedDictionary+Variadic.m
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

#import "OrderedDictionary+Variadic.h"
#import "Easydict-Swift.h"

@implementation MMOrderedDictionary (Variadic)

- (instancetype)initWithKeysAndObjects:(id)firstKey, ... {
    self = [self init];
    if (self && firstKey) {
        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *values = [NSMutableArray array];

        va_list argumentList;
        va_start(argumentList, firstKey);

        id currentKey = firstKey;
        NSInteger index = 0;

        while (currentKey) {
            [keys addObject:currentKey];

            id value = va_arg(argumentList, id);
            if (!value) {
                NSAssert(NO, @"MMOrderedDictionary: keys and values must be paired");
                va_end(argumentList);
                return nil;
            }
            [values addObject:value];

            currentKey = va_arg(argumentList, id);
            index++;
        }

        va_end(argumentList);

        // Add all key-value pairs
        for (NSInteger i = 0; i < keys.count; i++) {
            [self setObject:values[i] forKey:keys[i]];
        }
    }
    return self;
}

@end
