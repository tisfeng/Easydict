//
//  EZAppModel.m
//  Easydict
//
//  Created by tisfeng on 2023/6/21.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAppModel.h"

@implementation EZAppModel

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[EZAppModel class]]) {
        return NO;
    }
    
    EZAppModel *model = (EZAppModel *)object;
    return [self.appBundleID isEqualToString:model.appBundleID];
}

@end
