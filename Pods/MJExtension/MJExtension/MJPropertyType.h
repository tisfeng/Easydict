//
//  MJPropertyType.h
//  MJExtension
//
//  Created by mj on 14-1-15.
//  Copyright (c) 2014年 小码哥. All rights reserved.
//  包装一种类型

#import <Foundation/Foundation.h>

/**
 *  包装一种类型
 */
@interface MJPropertyType : NSObject
/** 类型标识符 */
@property (nonatomic, copy) NSString *code;

/** 是否为id类型 */
@property (nonatomic, readonly, getter=isIdType) BOOL idType;

/** 是否为基本数字类型：int、float等 */
@property (nonatomic, readonly, getter=isNumberType) BOOL numberType;

/** 是否为BOOL类型 */
@property (nonatomic, readonly, getter=isBoolType) BOOL boolType;

/** 对象类型（如果是基本数据类型，此值为nil） */
@property (nonatomic, readonly) Class typeClass;

/** 类型是否来自于Foundation框架，比如NSString、NSArray */
@property (nonatomic, readonly, getter = isFromFoundation) BOOL fromFoundation;
/** 类型是否不支持KVC */
@property (nonatomic, readonly, getter = isKVCDisabled) BOOL KVCDisabled;

/**
 *  获得缓存的类型对象
 */
+ (instancetype)cachedTypeWithCode:(NSString *)code;
@end