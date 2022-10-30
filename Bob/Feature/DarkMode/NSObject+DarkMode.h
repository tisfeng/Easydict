//
//  NSObject+DarkMode.h
//  Bob
//
//  Created by chen on 2019/12/25.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (DarkMode)

- (void)excuteLight:(void(^)(id x))light drak:(void(^)(id x))dark;

@end

NS_ASSUME_NONNULL_END
