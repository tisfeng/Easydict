//
//  NSView+EZWindowType.h
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZLayoutManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (EZWindowType)

@property (nonatomic, assign) EZWindowType associatedWindowType;


@end

NS_ASSUME_NONNULL_END
