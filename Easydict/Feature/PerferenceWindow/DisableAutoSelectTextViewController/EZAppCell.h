//
//  EZAppCell.h
//  Easydict
//
//  Created by tisfeng on 2023/6/16.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZAppModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZAppCell : NSView

@property (nonatomic, strong) EZAppModel *model;

@end

NS_ASSUME_NONNULL_END
