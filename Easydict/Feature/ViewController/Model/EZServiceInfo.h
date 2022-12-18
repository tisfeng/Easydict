//
//  EZServiceInfo.h
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZServiceTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZServiceInfo : NSObject

@property (nonatomic, assign) EZServiceType type;
@property (nonatomic, assign) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
