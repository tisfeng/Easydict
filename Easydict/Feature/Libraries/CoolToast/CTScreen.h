//
//  CTScreen.h
//  CoolToast
//
//  Created by Socoolby on 2019/7/1.
//  Copyright © 2019 Socoolby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTScreen : NSObject

//+ (NSScreen *)screenWithPoint:(CGPoint)point;
+ (CGPoint)mouseLocationInScreen;
+ (NSScreen *)getMainScreen;
+ (NSScreen *)getCurrentScreen;
+ (NSRect)frameForScreen:(NSScreen *)screen;

@end

NS_ASSUME_NONNULL_END
