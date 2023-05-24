//
//  NSUserDefaults+EZConfig.h
//  Easydict
//
//  Created by tisfeng on 2023/5/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZBetaFeatureKey = @"EZBetaFeatureKey";
//static NSString *const EZResetUserDefaultsDataKey = @"EZResetUserDefaultsDataKey";
//static NSString *const EZSaveUserDefaultsDataToDownloadFolderKey = @"EZSaveUserDefaultsDataToDownloadFolderKey";

@interface NSUserDefaults (EZConfig)

@property (nonatomic, assign, readonly, getter=isBeta) BOOL beta;

@property (nonatomic, assign, readonly) NSDictionary *userDefaultsData;

- (void)saveUserDefaultsDataToDownloadFolder;

- (void)resetUserDefaultsData;

@end

NS_ASSUME_NONNULL_END
