//
//  NSObject+MJProperty.m
//  MJExtensionExample
//
//  Created by MJ Lee on 15/4/17.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "NSObject+MJProperty.h"
#import "NSObject+MJKeyValue.h"
#import "NSObject+MJCoding.h"
#import "NSObject+MJClass.h"
#import "MJProperty.h"
#import "MJFoundation.h"
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

static const char MJReplacedKeyFromPropertyNameKey = '\0';
static const char MJReplacedKeyFromPropertyName121Key = '\0';
static const char MJNewValueFromOldValueKey = '\0';
static const char MJObjectClassInArrayKey = '\0';

static const char MJCachedPropertiesKey = '\0';

dispatch_semaphore_t mje_signalSemaphore;
dispatch_once_t mje_onceTokenSemaphore;

@implementation NSObject (Property)

+ (NSMutableDictionary *)mj_propertyDictForKey:(const void *)key
{
    static NSMutableDictionary *replacedKeyFromPropertyNameDict;
    static NSMutableDictionary *replacedKeyFromPropertyName121Dict;
    static NSMutableDictionary *newValueFromOldValueDict;
    static NSMutableDictionary *objectClassInArrayDict;
    static NSMutableDictionary *cachedPropertiesDict;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacedKeyFromPropertyNameDict = [NSMutableDictionary dictionary];
        replacedKeyFromPropertyName121Dict = [NSMutableDictionary dictionary];
        newValueFromOldValueDict = [NSMutableDictionary dictionary];
        objectClassInArrayDict = [NSMutableDictionary dictionary];
        cachedPropertiesDict = [NSMutableDictionary dictionary];
    });
    
    if (key == &MJReplacedKeyFromPropertyNameKey) return replacedKeyFromPropertyNameDict;
    if (key == &MJReplacedKeyFromPropertyName121Key) return replacedKeyFromPropertyName121Dict;
    if (key == &MJNewValueFromOldValueKey) return newValueFromOldValueDict;
    if (key == &MJObjectClassInArrayKey) return objectClassInArrayDict;
    if (key == &MJCachedPropertiesKey) return cachedPropertiesDict;
    return nil;
}

#pragma mark - --私有方法--
+ (id)mj_propertyKey:(NSString *)propertyName
{
    MJExtensionAssertParamNotNil2(propertyName, nil);
    
    __block id key = nil;
    // 查看有没有需要替换的key
    if ([self respondsToSelector:@selector(mj_replacedKeyFromPropertyName121:)]) {
        key = [self mj_replacedKeyFromPropertyName121:propertyName];
    }
    
    // 调用block
    if (!key) {
        [self mj_enumerateAllClasses:^(__unsafe_unretained Class c, BOOL *stop) {
            MJReplacedKeyFromPropertyName121 block = objc_getAssociatedObject(c, &MJReplacedKeyFromPropertyName121Key);
            if (block) {
                key = block(propertyName);
            }
            if (key) *stop = YES;
        }];
    }
    
    // 查看有没有需要替换的key
    if ((!key || [key isEqual:propertyName]) && [self respondsToSelector:@selector(mj_replacedKeyFromPropertyName)]) {
        key = [self mj_replacedKeyFromPropertyName][propertyName];
    }
    
    if (!key || [key isEqual:propertyName]) {
        [self mj_enumerateAllClasses:^(__unsafe_unretained Class c, BOOL *stop) {
            NSDictionary *dict = objc_getAssociatedObject(c, &MJReplacedKeyFromPropertyNameKey);
            if (dict) {
                key = dict[propertyName];
            }
            if (key && ![key isEqual:propertyName]) *stop = YES;
        }];
    }
    
    // 2.用属性名作为key
    if (!key) key = propertyName;
    
    return key;
}

+ (Class)mj_propertyObjectClassInArray:(NSString *)propertyName
{
    __block id clazz = nil;
    if ([self respondsToSelector:@selector(mj_objectClassInArray)]) {
        clazz = [self mj_objectClassInArray][propertyName];
    }
    
    if (!clazz) {
        [self mj_enumerateAllClasses:^(__unsafe_unretained Class c, BOOL *stop) {
            NSDictionary *dict = objc_getAssociatedObject(c, &MJObjectClassInArrayKey);
            if (dict) {
                clazz = dict[propertyName];
            }
            if (clazz) *stop = YES;
        }];
    }
    
    // 如果是NSString类型
    if ([clazz isKindOfClass:[NSString class]]) {
        clazz = NSClassFromString(clazz);
    }
    return clazz;
}

#pragma mark - --公共方法--
+ (void)mj_enumerateProperties:(MJPropertiesEnumeration)enumeration
{
    // 获得成员变量
    MJExtensionSemaphoreCreate
    MJ_LOCK(mje_signalSemaphore);
    NSArray *cachedProperties = [self mj_properties];
    MJ_UNLOCK(mje_signalSemaphore);
    // 遍历成员变量
    BOOL stop = NO;
    for (MJProperty *property in [cachedProperties copy]) {
        enumeration(property, &stop);
        if (stop) break;
    }
}

#pragma mark - 公共方法
+ (NSMutableArray *)mj_properties
{
    NSMutableDictionary *cachedInfo = [self mj_propertyDictForKey:&MJCachedPropertiesKey];
    NSMutableArray *cachedProperties = cachedInfo[NSStringFromClass(self)];
    if (cachedProperties == nil) {
        cachedProperties = [NSMutableArray array];
        
        [self mj_enumerateClasses:^(__unsafe_unretained Class c, BOOL *stop) {
            // 1.获得所有的成员变量
            unsigned int outCount = 0;
            objc_property_t *properties = class_copyPropertyList(c, &outCount);
            
            // 2.遍历每一个成员变量
            for (unsigned int i = 0; i<outCount; i++) {
                MJProperty *property = [MJProperty cachedPropertyWithProperty:properties[i]];
                // 过滤掉Foundation框架类里面的属性
                if ([MJFoundation isClassFromFoundation:property.srcClass]) continue;
                // 过滤掉`hash`, `superclass`, `description`, `debugDescription`
                if ([MJFoundation isFromNSObjectProtocolProperty:property.name]) continue;
                
                property.srcClass = c;
                [property setOriginKey:[self mj_propertyKey:property.name] forClass:self];
                [property setObjectClassInArray:[self mj_propertyObjectClassInArray:property.name] forClass:self];
                [cachedProperties addObject:property];
            }
            
            // 3.释放内存
            free(properties);
        }];
        
        [self mj_propertyDictForKey:&MJCachedPropertiesKey][NSStringFromClass(self)] = cachedProperties;
    }
    
    return cachedProperties;
}

#pragma mark - 新值配置
+ (void)mj_setupNewValueFromOldValue:(MJNewValueFromOldValue)newValueFormOldValue
{
    objc_setAssociatedObject(self, &MJNewValueFromOldValueKey, newValueFormOldValue, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)mj_getNewValueFromObject:(__unsafe_unretained id)object oldValue:(__unsafe_unretained id)oldValue property:(MJProperty *__unsafe_unretained)property{
    // 如果有实现方法
    if ([object respondsToSelector:@selector(mj_newValueFromOldValue:property:)]) {
        return [object mj_newValueFromOldValue:oldValue property:property];
    }
    
    // 查看静态设置
    __block id newValue = oldValue;
    [self mj_enumerateAllClasses:^(__unsafe_unretained Class c, BOOL *stop) {
        MJNewValueFromOldValue block = objc_getAssociatedObject(c, &MJNewValueFromOldValueKey);
        if (block) {
            newValue = block(object, oldValue, property);
            *stop = YES;
        }
    }];
    return newValue;
}

#pragma mark - array model class配置
+ (void)mj_setupObjectClassInArray:(MJObjectClassInArray)objectClassInArray
{
    [self mj_setupBlockReturnValue:objectClassInArray key:&MJObjectClassInArrayKey];
    
    MJExtensionSemaphoreCreate
    MJ_LOCK(mje_signalSemaphore);
    [[self mj_propertyDictForKey:&MJCachedPropertiesKey] removeAllObjects];
    MJ_UNLOCK(mje_signalSemaphore);
}

#pragma mark - key配置
+ (void)mj_setupReplacedKeyFromPropertyName:(MJReplacedKeyFromPropertyName)replacedKeyFromPropertyName
{
    [self mj_setupBlockReturnValue:replacedKeyFromPropertyName key:&MJReplacedKeyFromPropertyNameKey];
    
    MJExtensionSemaphoreCreate
    MJ_LOCK(mje_signalSemaphore);
    [[self mj_propertyDictForKey:&MJCachedPropertiesKey] removeAllObjects];
    MJ_UNLOCK(mje_signalSemaphore);
}

+ (void)mj_setupReplacedKeyFromPropertyName121:(MJReplacedKeyFromPropertyName121)replacedKeyFromPropertyName121
{
    objc_setAssociatedObject(self, &MJReplacedKeyFromPropertyName121Key, replacedKeyFromPropertyName121, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    MJExtensionSemaphoreCreate
    MJ_LOCK(mje_signalSemaphore);
    [[self mj_propertyDictForKey:&MJCachedPropertiesKey] removeAllObjects];
    MJ_UNLOCK(mje_signalSemaphore);
}
@end
#pragma clang diagnostic pop
