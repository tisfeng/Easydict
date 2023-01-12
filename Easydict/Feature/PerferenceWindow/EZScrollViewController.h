//
//  EZScrollViewController.h
//  Easydict
//
//  Created by tisfeng on 2023/1/11.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZScrollViewController : NSViewController

@property (nonatomic, strong) NSView *contentView;

@property (nonatomic, strong) NSView *leftmostView;
@property (nonatomic, strong) NSView *rightmostView;
@property (nonatomic, strong) NSView *topmostView;
@property (nonatomic, strong) NSView *bottommostView;

@property (nonatomic, assign) CGSize maxViewSize; // 最大的view的size

@property (nonatomic, assign) CGFloat verticalMargin; // 顶部和底部的间距 30
@property (nonatomic, assign) CGFloat horizontalMargin; // 左右的间距 50
@property (nonatomic, assign) CGFloat verticalPadding; // 垂直内容的间距 15
@property (nonatomic, assign) CGFloat horizontalPadding; // 水平内容的间距 8

@property (nonatomic, assign) CGFloat topMargin; // 顶部的间距 30
@property (nonatomic, assign) CGFloat bottomMargin; // 底部的间距 30
@property (nonatomic, assign) CGFloat leftMargin; // 左边的间距 50
@property (nonatomic, assign) CGFloat rightMargin; // 右边的间距 50

- (void)updateViewSize;

@end

NS_ASSUME_NONNULL_END
