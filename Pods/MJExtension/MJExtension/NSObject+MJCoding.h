//
//  NSObject+MJCoding.h
//  MJExtension
//
//  Created by mj on 14-1-15.
//  Copyright (c) 2014年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtensionConst.h"

/**
 *  Codeing协议
 */
@protocol MJCoding <NSObject>
@optional
/**
 *  这个数组中的属性名才会进行归档
 */
+ (NSArray *)mj_allowedCodingPropertyNames;
/**
 *  这个数组中的属性名将会被忽略：不进行归档
 */
+ (NSArray *)mj_ignoredCodingPropertyNames;
@end

@interface NSObject (MJCoding) <MJCoding>
/**
 *  解码（从文件中解析对象）
 */
- (void)mj_decode:(NSCoder *)decoder;
/**
 *  编码（将对象写入文件中）
 */
- (void)mj_encode:(NSCoder *)encoder;
@end

/**
 归档的实现
 */
#define MJCodingImplementation \
- (id)initWithCoder:(NSCoder *)decoder \
{ \
if (self = [super init]) { \
[self mj_decode:decoder]; \
} \
return self; \
} \
\
- (void)encodeWithCoder:(NSCoder *)encoder \
{ \
[self mj_encode:encoder]; \
}

#define MJExtensionCodingImplementation MJCodingImplementation