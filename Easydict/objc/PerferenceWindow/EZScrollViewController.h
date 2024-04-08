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

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSView *contentView;

@property (nonatomic, strong) NSView *leftmostView;
@property (nonatomic, strong) NSView *rightmostView;
@property (nonatomic, strong) NSView *topmostView;
@property (nonatomic, strong) NSView *bottommostView;

@property (nonatomic, assign) CGSize maxViewSize; // Max self.view size.
@property (nonatomic, assign) CGFloat maxViewHeightRatio; // 0.7
@property (nonatomic, assign) CGFloat maxViewWidthRatio; // 0.8

@property (nonatomic, assign) CGFloat verticalPadding; // 15
@property (nonatomic, assign) CGFloat horizontalPadding; // 8

@property (nonatomic, assign) CGFloat topMargin; // 30
@property (nonatomic, assign) CGFloat bottomMargin; // 30
@property (nonatomic, assign) CGFloat leftMargin; // 50
@property (nonatomic, assign) CGFloat rightMargin; // 50

- (void)updateViewSize;

@end

NS_ASSUME_NONNULL_END
