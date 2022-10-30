//
//  NSObject+MJClass.h
//  MJExtensionExample
//
//  Created by MJ Lee on 15/8/11.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  遍历所有类的block（父类）
 */
typedef void (^MJClassesEnumeration)(Class c, BOOL *stop);

/** 这个数组中的属性名才会进行字典和模型的转换 */
typedef NSArray * (^MJAllowedPropertyNames)(void);
/** 这个数组中的属性名才会进行归档 */
typedef NSArray * (^MJAllowedCodingPropertyNames)(void);

/** 这个数组中的属性名将会被忽略：不进行字典和模型的转换 */
typedef NSArray * (^MJIgnoredPropertyNames)(void);
/** 这个数组中的属性名将会被忽略：不进行归档 */
typedef NSArray * (^MJIgnoredCodingPropertyNames)(void);

/**
 * 类相关的扩展
 */
@interface NSObject (MJClass)
/**
 *  遍历所有的类
 */
+ (void)mj_enumerateClasses:(MJClassesEnumeration)enumeration;
+ (void)mj_enumerateAllClasses:(MJClassesEnumeration)enumeration;

#pragma mark - 属性白名单配置
/**
 *  这个数组中的属性名才会进行字典和模型的转换
 *
 *  @param allowedPropertyNames          这个数组中的属性名才会进行字典和模型的转换
 */
+ (void)mj_setupAllowedPropertyNames:(MJAllowedPropertyNames)allowedPropertyNames;

/**
 *  这个数组中的属性名才会进行字典和模型的转换
 */
+ (NSMutableArray *)mj_totalAllowedPropertyNames;

#pragma mark - 属性黑名单配置
/**
 *  这个数组中的属性名将会被忽略：不进行字典和模型的转换
 *
 *  @param ignoredPropertyNames          这个数组中的属性名将会被忽略：不进行字典和模型的转换
 */
+ (void)mj_setupIgnoredPropertyNames:(MJIgnoredPropertyNames)ignoredPropertyNames;

/**
 *  这个数组中的属性名将会被忽略：不进行字典和模型的转换
 */
+ (NSMutableArray *)mj_totalIgnoredPropertyNames;

#pragma mark - 归档属性白名单配置
/**
 *  这个数组中的属性名才会进行归档
 *
 *  @param allowedCodingPropertyNames          这个数组中的属性名才会进行归档
 */
+ (void)mj_setupAllowedCodingPropertyNames:(MJAllowedCodingPropertyNames)allowedCodingPropertyNames;

/**
 *  这个数组中的属性名才会进行字典和模型的转换
 */
+ (NSMutableArray *)mj_totalAllowedCodingPropertyNames;

#pragma mark - 归档属性黑名单配置
/**
 *  这个数组中的属性名将会被忽略：不进行归档
 *
 *  @param ignoredCodingPropertyNames          这个数组中的属性名将会被忽略：不进行归档
 */
+ (void)mj_setupIgnoredCodingPropertyNames:(MJIgnoredCodingPropertyNames)ignoredCodingPropertyNames;

/**
 *  这个数组中的属性名将会被忽略：不进行归档
 */
+ (NSMutableArray *)mj_totalIgnoredCodingPropertyNames;

#pragma mark - 内部使用
+ (void)mj_setupBlockReturnValue:(id (^)(void))block key:(const char *)key;
@end
