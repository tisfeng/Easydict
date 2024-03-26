//
//  DarkModeManager.h
//  Bob
//
//  Created by chen on 2019/12/24.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DarkModeManager : NSObject

@property (nonatomic, assign, readonly) BOOL systemDarkMode;

+ (instancetype)manager NS_SWIFT_NAME(sharedManager());
- (void)excuteLight:(void (^)(void))light dark:(void (^)(void))dark;

- (void)updateDarkMode:(NSInteger)apperance;

@end

NS_ASSUME_NONNULL_END
