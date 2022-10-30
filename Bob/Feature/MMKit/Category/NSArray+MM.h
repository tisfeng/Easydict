//
//  NSArray+MM.h
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant ObjectType> (MM)

/// 遍历处理元素并将返回的数据组成新数组
- (NSArray *)mm_map:(id _Nullable (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

/// 遍历过滤元素并组成新数组
- (NSArray<ObjectType> *)mm_where:(BOOL (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

/// 遍历数组查找某一个元素，找到之后返回元素（可以进行处理），并自动停止遍历；没有找到则返回 nil
- (id)mm_find:(id _Nullable (^)(ObjectType obj, NSUInteger idx))block;

/// 遍历处理元素并将返回的数组组成一个大数组
- (NSArray *)mm_combine:(NSArray * _Nullable (^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

/// 生成一个从元素获取 index 的字典，元素必须唯一
- (NSDictionary<ObjectType, NSNumber *> *)mm_objectToIndexDictionary;

@end

NS_ASSUME_NONNULL_END
