//
//  NSArray+MM.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSArray+MM.h"

@implementation NSArray (MM)

- (NSArray *)mm_map:(id (^)(id obj, NSUInteger idx, BOOL *stop))block {
    __block NSMutableArray *newArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSObject *newObj = block(obj, idx, stop);
        if (newObj) {
            [newArray addObject:newObj];
        }
    }];
    return newArray.copy;
}

- (NSArray *)mm_where:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))block {
    __block NSMutableArray *newArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (block(obj, idx, stop)) {
            [newArray addObject:obj];
        }
    }];
    return newArray.copy;
}

- (id)mm_find:(id (^)(id _Nonnull, NSUInteger))block {
    __block id target = nil;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id result = block(obj, idx);
        if (result) {
            target = result;
            *stop = YES;
        }
    }];
    return target;
}

- (NSArray *)mm_combine:(NSArray * (^)(id obj, NSUInteger idx, BOOL *stop))block {
    __block NSMutableArray *newArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *oneArray = block(obj, idx, stop);
        if (oneArray.count) {
            [newArray addObjectsFromArray:oneArray];
        }
    }];
    return newArray.copy;
}

- (NSDictionary *)mm_objectToIndexDictionary {
    __block NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MMAssert(![newDict objectForKey:obj], @"数组不能包含相同元素");
        [newDict setObject:@(idx) forKey:obj];
    }];
    return newDict.copy;
}

@end
