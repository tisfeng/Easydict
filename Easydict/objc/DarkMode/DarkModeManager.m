//
//  DarkModeManager.m
//  Bob
//
//  Created by chen on 2019/12/24.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "DarkModeManager.h"

@interface DarkModeManager ()

@property (nonatomic, assign) BOOL systemDarkMode;

@end


@implementation DarkModeManager

singleton_m(DarkModeManager);

+ (void)load {
    [[self manager] monitor];
}

+ (instancetype)manager {
    return [self shared];
}


- (void)excuteLight:(void (^)(void))light dark:(void (^)(void))dark {
    [RACObserve([DarkModeManager manager], systemDarkMode) subscribeNext:^(id _Nullable x) {
        if ([x boolValue]) {
            !dark ?: dark();
        } else {
            !light ?: light();
        }
    }];
}

- (void)monitor {
    NSString *const darkModeNotificationName = @"AppleInterfaceThemeChangedNotification";
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:darkModeNotificationName object:nil];
}

- (void)themeDidChange {
    [self updateDarkMode:Configuration.shared.appearance];
}

- (void)updateDarkMode:(NSInteger)apperance {
    BOOL isDarkMode = [self isDarkMode];
    MMLogInfo(@"%@", isDarkMode ? @"深色模式" : @"浅色模式");
    
    AppearenceType type = apperance;
    switch (type) {
        case AppearenceTypeDark:
            self.systemDarkMode = true;
            break;
        case AppearenceTypeLight:
            self.systemDarkMode = false;
            break;
        case AppearenceTypeFollowSystem:
            self.systemDarkMode = isDarkMode;
            break;
        default:
            break;
    }
    
    [AppearenceHelper.shared updateAppApperance:type];
}

- (BOOL)isDarkMode {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    NSString *appleInterfaceStyle = [dict objectForKey:@"AppleInterfaceStyle"];
    BOOL isDarkMode = [appleInterfaceStyle isEqualToString:@"Dark"];
    return isDarkMode;
}

@end
