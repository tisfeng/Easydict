//
//  NSImage+EZResize.h
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (EZResize)

- (NSImage *)resizeToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
