//
//  Snip.h
//  Bob
//
//  Created by ripper on 2019/11/27.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SnipWindowController.h"

NS_ASSUME_NONNULL_BEGIN

@interface Snip : NSObject

@property (nonatomic, assign) BOOL isSnapshotting;

+ (instancetype)shared;

- (void)startWithCompletion:(void (^)(NSImage * _Nullable image))completion;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
