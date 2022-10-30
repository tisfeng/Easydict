//
//  NSDictionary+MM.m
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSDictionary+MM.h"

@implementation NSDictionary (MM)

- (NSDictionary *)mm_reverseKeysAndObjectsDictionary {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert(![dic objectForKey:obj], @"获取逆反字典不能有重复的 obj");
        [dic setObject:key forKey:obj];
    }];
    if (dic.count == self.count) {
        return dic.copy;
    }else {
        return nil;
    }
}

@end
