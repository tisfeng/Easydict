//
//  StatusItem.h
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StatusItem : NSObject

@property (nonatomic, strong, nullable) NSStatusItem *statusItem;

+ (instancetype)shared;

- (void)setup;

- (void)remove;

@end

NS_ASSUME_NONNULL_END
