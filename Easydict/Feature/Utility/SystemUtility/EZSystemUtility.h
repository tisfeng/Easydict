//
//  EZSystemUtility.h
//  Easydict
//
//  Created by tisfeng on 2023/10/15.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZSystemUtility : NSObject

#pragma mark - Simulate Key Event

+ (void)postCopyEvent;
+ (void)postPasteEvent;

+ (void)postKeyboardEvent:(CGEventFlags)flags virtualKey:(CGKeyCode)virtualKey keyDown:(bool)keyDown;

#pragma mark -

+ (BOOL)isSelectedTextEditable;

+ (NSString *)getLastPasteboardText;

@end


NS_ASSUME_NONNULL_END
