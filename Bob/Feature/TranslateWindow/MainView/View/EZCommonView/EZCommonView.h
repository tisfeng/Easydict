//
//  EDAudioView.h
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZCommonView : NSView

@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, strong) NSButton *audioButton;
@property (nonatomic, strong) NSButton *textCopyButton;

@property (nonatomic, copy) void (^audioActionBlock)(NSString *text);
@property (nonatomic, copy) void (^copyActionBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
