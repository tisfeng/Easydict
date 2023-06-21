//
//  EZConfiguration+EZUserData.h
//  Easydict
//
//  Created by tisfeng on 2023/6/21.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZConfiguration (EZUserData)

@property (nonatomic, assign, readonly) NSDictionary *userDefaultsData;

- (void)saveUserDefaultsDataToDownloadFolder;

- (void)resetUserDefaultsData;

@end

NS_ASSUME_NONNULL_END
