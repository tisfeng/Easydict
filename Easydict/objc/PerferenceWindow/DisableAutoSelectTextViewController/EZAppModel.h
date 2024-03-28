//
//  EZAppModel.h
//  Easydict
//
//  Created by tisfeng on 2023/6/21.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZAppModel : NSObject

@property (nonatomic, copy) NSString *appBundleID;
@property (nonatomic, assign) EZTriggerType triggerType;

@end

NS_ASSUME_NONNULL_END
