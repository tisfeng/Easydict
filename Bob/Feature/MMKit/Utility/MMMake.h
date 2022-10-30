//
//  MMMake.h
//  Bob
//
//  Created by ripper on 2019/11/12.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

/// 定义 MMMake 方法
#define DefineMethodMMMake_h(class, obj) \
+ (instancetype)mm_make:(void (NS_NOESCAPE ^)(class *obj))block; \
+ (instancetype)mm_anyMake:(void (NS_NOESCAPE ^)(id obj))block; \
- (id)mm_put:(void (NS_NOESCAPE ^)(class *obj))block; \
- (id)mm_anyPut:(void (NS_NOESCAPE ^)(id obj))block;

/// 实现 MMMake 方法
#define DefineMethodMMMake_m(class) \
+ (instancetype)mm_make:(void (NS_NOESCAPE ^)(class * _Nonnull))block { \
id obj = [self new]; \
block(obj); \
return obj; \
} \
+ (instancetype)mm_anyMake:(void (NS_NOESCAPE ^)(id _Nonnull))block { \
id obj = [self new]; \
block(obj); \
return obj; \
} \
- (id)mm_put:(void (NS_NOESCAPE ^)(class * _Nonnull))block { \
block(self); \
return self; \
} \
- (id)mm_anyPut:(void (NS_NOESCAPE ^)(id _Nonnull))block { \
block(self); \
return self; \
}

/// 定义 MMMake 分类
#define DefineCategoryMMMake_h(class, obj) \
@interface class (MMMake) \
DefineMethodMMMake_h(class, obj) \
@end

/// 实现 MMMake 分类
#define DefineCategoryMMMake_m(class) \
@implementation class (MMMake) \
DefineMethodMMMake_m(class) \
@end


NS_ASSUME_NONNULL_BEGIN


/// 这个分类可以用宏定义实现，不过为了方便看注释，暂且手写
@interface NSObject (MMMake)

/// 初始化一个对象，并在block中作为参数传入
+ (instancetype)mm_make:(void (NS_NOESCAPE ^)(id obj))block;
/// 同上，用于自定义类型手动修改类型（防止警告）
+ (instancetype)mm_anyMake:(void (NS_NOESCAPE ^)(id obj))block;

/// 用于传入self到block中进行操作
- (id)mm_put:(void (NS_NOESCAPE ^)(id obj))block;
/// 同上，用于自定义类型手动修改类型（防止警告）
- (id)mm_anyPut:(void (NS_NOESCAPE ^)(id obj))block;

@end

DefineCategoryMMMake_h(NSView, view)
DefineCategoryMMMake_h(NSButton, button)
DefineCategoryMMMake_h(NSTextField, textField)
DefineCategoryMMMake_h(NSTextView, textView)
DefineCategoryMMMake_h(NSScrollView, scrollView)
DefineCategoryMMMake_h(NSImageView, imageView)

NS_ASSUME_NONNULL_END
