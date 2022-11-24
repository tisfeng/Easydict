//
//  EZStatusItem.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZStatusItem : NSObject

@property (nonatomic, strong, nullable) NSStatusItem *statusItem;

+ (instancetype)shared;

- (void)setup;

- (void)remove;

@end

NS_ASSUME_NONNULL_END
