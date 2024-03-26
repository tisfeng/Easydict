//
//  EZStatusItem.h
//  Easydict
//
//  Created by tisfeng on 2022/11/16.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZMenuItemManager : NSObject

@property (nonatomic, strong, nullable) NSStatusItem *statusItem;

@property (weak) IBOutlet NSMenuItem *googleItem;
@property (weak) IBOutlet NSMenuItem *eudicItem;
@property (weak) IBOutlet NSMenuItem *appleDictionaryItem;

+ (instancetype)shared;

- (void)setup;

- (void)remove;

- (void)fetchRepoLatestVersion:(NSString *)repo completion:(void (^)(NSString *lastestVersion))completion;

- (void)fetchRepoLatestRepoInfo:(NSString *)repo completion:(void (^)(NSDictionary *lastestVersionDict))completion;

@end

NS_ASSUME_NONNULL_END
