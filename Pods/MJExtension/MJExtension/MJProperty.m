//
//  MJProperty.m
//  MJExtensionExample
//
//  Created by MJ Lee on 15/4/17.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "MJProperty.h"
#import "MJFoundation.h"
#import "MJExtensionConst.h"
#import <objc/message.h>
#include "TargetConditionals.h"

@interface MJProperty()
@property (strong, nonatomic) NSMutableDictionary *propertyKeysDict;
@property (strong, nonatomic) NSMutableDictionary *objectClassInArrayDict;
@property (strong, nonatomic) dispatch_semaphore_t propertyKeysLock;
@property (strong, nonatomic) dispatch_semaphore_t objectClassInArrayLock;
@end

@implementation MJProperty

#pragma mark - 初始化
- (instancetype)init
{
    if (self = [super init]) {
        _propertyKeysDict = [NSMutableDictionary dictionary];
        _objectClassInArrayDict = [NSMutableDictionary dictionary];
        _propertyKeysLock = dispatch_semaphore_create(1);
        _objectClassInArrayLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - 缓存
+ (instancetype)cachedPropertyWithProperty:(objc_property_t)property
{
    MJProperty *propertyObj = objc_getAssociatedObject(self, property);
    if (propertyObj == nil) {
        propertyObj = [[self alloc] init];
        propertyObj.property = property;
        objc_setAssociatedObject(self, property, propertyObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return propertyObj;
}

#pragma mark - 公共方法
- (void)setProperty:(objc_property_t)property
{
    _property = property;
    
    MJExtensionAssertParamNotNil(property);
    
    // 1.属性名
    _name = @(property_getName(property));
    
    // 2.成员类型
    NSString *attrs = @(property_getAttributes(property));
    NSUInteger dotLoc = [attrs rangeOfString:@","].location;
    NSString *code = nil;
    NSUInteger loc = 1;
    if (dotLoc == NSNotFound) { // 没有,
        code = [attrs substringFromIndex:loc];
    } else {
        code = [attrs substringWithRange:NSMakeRange(loc, dotLoc - loc)];
    }
    _type = [MJPropertyType cachedTypeWithCode:code];
}

/**
 *  获得成员变量的值
 */
- (id)valueForObject:(id)object
{
    if (self.type.KVCDisabled) return [NSNull null];
    
    id value = [object valueForKey:self.name];
    
    // 32位BOOL类型转换json后成Int类型
    /** https://github.com/CoderMJLee/MJExtension/issues/545 */
    // 32 bit device OR 32 bit Simulator
#if defined(__arm__) || (TARGET_OS_SIMULATOR && !__LP64__)
    if (self.type.isBoolType) {
        value = @([(NSNumber *)value boolValue]);
    }
#endif
    
    return value;
}

/**
 *  设置成员变量的值
 */
- (void)setValue:(id)value forObject:(id)object
{
    if (self.type.KVCDisabled || value == nil) return;
    [object setValue:value forKey:self.name];
}

/**
 *  通过字符串key创建对应的keys
 */
- (NSArray *)propertyKeysWithStringKey:(NSString *)stringKey
{
    if (stringKey.length == 0) return nil;
    
    NSMutableArray *propertyKeys = [NSMutableArray array];
    // 如果有多级映射
    NSArray *oldKeys = [stringKey componentsSeparatedByString:@"."];
    
    for (NSString *oldKey in oldKeys) {
        NSUInteger start = [oldKey rangeOfString:@"["].location;
        if (start != NSNotFound) { // 有索引的key
            NSString *prefixKey = [oldKey substringToIndex:start];
            NSString *indexKey = prefixKey;
            if (prefixKey.length) {
                MJPropertyKey *propertyKey = [[MJPropertyKey alloc] init];
                propertyKey.name = prefixKey;
                [propertyKeys addObject:propertyKey];
                
                indexKey = [oldKey stringByReplacingOccurrencesOfString:prefixKey withString:@""];
            }
            
            /** 解析索引 **/
            // 元素
            NSArray *cmps = [[indexKey stringByReplacingOccurrencesOfString:@"[" withString:@""] componentsSeparatedByString:@"]"];
            for (NSInteger i = 0; i<cmps.count - 1; i++) {
                MJPropertyKey *subPropertyKey = [[MJPropertyKey alloc] init];
                subPropertyKey.type = MJPropertyKeyTypeArray;
                subPropertyKey.name = cmps[i];
                [propertyKeys addObject:subPropertyKey];
            }
        } else { // 没有索引的key
            MJPropertyKey *propertyKey = [[MJPropertyKey alloc] init];
            propertyKey.name = oldKey;
            [propertyKeys addObject:propertyKey];
        }
    }
    
    return propertyKeys;
}

/** 对应着字典中的key */
- (void)setOriginKey:(id)originKey forClass:(Class)c
{
    if ([originKey isKindOfClass:[NSString class]]) { // 字符串类型的key
        NSArray *propertyKeys = [self propertyKeysWithStringKey:originKey];
        if (propertyKeys.count) {
            [self setPropertyKeys:@[propertyKeys] forClass:c];
        }
    } else if ([originKey isKindOfClass:[NSArray class]]) {
        NSMutableArray *keyses = [NSMutableArray array];
        for (NSString *stringKey in originKey) {
            NSArray *propertyKeys = [self propertyKeysWithStringKey:stringKey];
            if (propertyKeys.count) {
                [keyses addObject:propertyKeys];
            }
        }
        if (keyses.count) {
            [self setPropertyKeys:keyses forClass:c];
        }
    }
}

/** 对应着字典中的多级key */
- (void)setPropertyKeys:(NSArray *)propertyKeys forClass:(Class)c
{
    if (propertyKeys.count == 0) return;
    NSString *key = NSStringFromClass(c);
    if (!key) return;
    
    MJ_LOCK(self.propertyKeysLock);
    self.propertyKeysDict[key] = propertyKeys;
    MJ_UNLOCK(self.propertyKeysLock);
}

- (NSArray *)propertyKeysForClass:(Class)c
{
    NSString *key = NSStringFromClass(c);
    if (!key) return nil;
    
    MJ_LOCK(self.propertyKeysLock);
    NSArray *propertyKeys = self.propertyKeysDict[key];
    MJ_UNLOCK(self.propertyKeysLock);
    return propertyKeys;
}

/** 模型数组中的模型类型 */
- (void)setObjectClassInArray:(Class)objectClass forClass:(Class)c
{
    if (!objectClass) return;
    NSString *key = NSStringFromClass(c);
    if (!key) return;
    
    MJ_LOCK(self.objectClassInArrayLock);
    self.objectClassInArrayDict[key] = objectClass;
    MJ_UNLOCK(self.objectClassInArrayLock);
}

- (Class)objectClassInArrayForClass:(Class)c
{
    NSString *key = NSStringFromClass(c);
    if (!key) return nil;
    
    MJ_LOCK(self.objectClassInArrayLock);
    Class objectClass = self.objectClassInArrayDict[key];
    MJ_UNLOCK(self.objectClassInArrayLock);
    return objectClass;
}
@end
