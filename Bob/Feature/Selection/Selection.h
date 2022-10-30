//
//  Selection.h
//  Bob
//
//  Created by ripper on 2019/10/19.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Selection : NSObject

+ (void)getText:(void (^)(NSString * _Nullable text))completion;

@end

NS_ASSUME_NONNULL_END
