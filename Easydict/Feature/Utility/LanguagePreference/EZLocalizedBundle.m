//
//  EZLocalizedBundle.m
//  Easydict
//
//  Created by choykarl on 2024/3/21.
//  Copyright © 2024 izual. All rights reserved.
//

#import "EZLocalizedBundle.h"
#import <objc/runtime.h>

@implementation NSBundle (localized)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [EZLocalizedBundle class]);
    });
}

@end

@implementation EZLocalizedBundle
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSBundle *localizedBundle = [self localizedBundle];
    if (localizedBundle) {
        return [localizedBundle localizedStringForKey:key value:value table:tableName];
    } else {
        return [super localizedStringForKey:key value:value table:tableName];
    }
}

- (NSBundle *)localizedBundle {
    NSString *localizeCode = EZI18nHelper.shared.localizeCode;
    if (localizeCode.length) {
        NSString *path = [[NSBundle mainBundle] pathForResource:localizeCode ofType:@"lproj"];
        if (path.length) {
            return [NSBundle bundleWithPath:path];
        }
    }
    return nil;
}
@end
