//
//  HWSegmentedControl.h
//  Bus Servo Control
//
//  Created by xia luzheng on 2019/11/15.
//  Copyright © 2019 HiWonder. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HWSegmentedControlDelegate <NSObject>

- (void)selectTitleIndex:(NSInteger)index;

@end


@interface HWSegmentedControl : NSView

@property (nonatomic, strong) NSArray  *titles;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) float  maginLeftTwo;//字离左或右的边距 默认20

// The tintColor is inherited through the superview hierarchy. See UIView for more information.
@property(nonatomic,strong) NSColor *tintColor;

@property (nonatomic, assign) CGFloat cornerRadius;//圆角
@property (nonatomic, assign) CGFloat borderWidth;//边框宽
@property (nonatomic, weak) id<HWSegmentedControlDelegate> delegate;

- (void)reFresh;

@end

NS_ASSUME_NONNULL_END
