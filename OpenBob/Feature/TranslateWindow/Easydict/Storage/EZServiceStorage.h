//
//  EZServiceStorage.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZServiceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZServiceStorage : NSObject

+ (instancetype)shared;

- (EZServiceInfo *)getServiceInfo:(EZServiceType)type;
- (void)saveServiceInfo:(EZServiceInfo *)info type: (EZServiceType)type;

- (void)setServiceType:(EZServiceType)type enabled:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
