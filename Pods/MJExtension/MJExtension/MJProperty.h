//
//  MJProperty.h
//  MJExtensionExample
//
//  Created by MJ Lee on 15/4/17.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//  包装一个成员属性

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "MJPropertyType.h"
#import "MJPropertyKey.h"

/**
 *  包装一个成员
 */
@interface MJProperty : NSObject
/** 成员属性 */
@property (nonatomic, assign) objc_property_t property;
/** 成员属性的名字 */
@property (nonatomic, readonly) NSString *name;

/** 成员属性的类型 */
@property (nonatomic, readonly) MJPropertyType *type;
/** 成员属性来源于哪个类（可能是父类） */
@property (nonatomic, assign) Class srcClass;

/**** 同一个成员属性 - 父类和子类的行为可能不一致（originKey、propertyKeys、objectClassInArray） ****/
/** 设置最原始的key */
- (void)setOriginKey:(id)originKey forClass:(Class)c;
/** 对应着字典中的多级key（里面存放的数组，数组里面都是MJPropertyKey对象） */
- (NSArray *)propertyKeysForClass:(Class)c;

/** 模型数组中的模型类型 */
- (void)setObjectClassInArray:(Class)objectClass forClass:(Class)c;
- (Class)objectClassInArrayForClass:(Class)c;
/**** 同一个成员变量 - 父类和子类的行为可能不一致（key、keys、objectClassInArray） ****/

/**
 * 设置object的成员变量值
 */
- (void)setValue:(id)value forObject:(id)object;
/**
 * 得到object的成员属性值
 */
- (id)valueForObject:(id)object;

/**
 *  初始化
 */
+ (instancetype)cachedPropertyWithProperty:(objc_property_t)property;

@end
