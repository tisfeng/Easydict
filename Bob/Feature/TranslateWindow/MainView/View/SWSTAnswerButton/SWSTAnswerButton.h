//
//  SWSTAnswerButton.h
//  SWST_MAC
//
//  Created by maulyn on 2018/4/13.
//  Copyright © 2018年 cvte. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, SWSTAnswerButtonState) {
    SWSTAnswerButtonNormalState      = 0,
    SWSTAnswerButtonHoverState       = 1,
    SWSTAnswerButtonHighlightState   = 2,
    SWSTAnswerButtonSelectedState    = 3
};

@interface SWSTAnswerButton : NSButton

@property (nonatomic, assign) BOOL canSelected; //default YES.
@property (nonatomic, assign) BOOL hasBorder;

@property (nonatomic, assign) SWSTAnswerButtonState buttonState;

@property (nonatomic, assign) CGFloat cornerNormalRadius;
@property (nonatomic, assign) CGFloat cornerHoverRadius;
@property (nonatomic, assign) CGFloat cornerHighlightRadius;
@property (nonatomic, assign) CGFloat cornerSelectedRadius;

@property (nonatomic, assign) CGFloat borderNormalWidth;
@property (nonatomic, assign) CGFloat borderHoverWidth;
@property (nonatomic, assign) CGFloat borderHighlightWidth;
@property (nonatomic, assign) CGFloat borderSelectedWidth;

@property (nonatomic, strong) NSColor *borderNormalColor;
@property (nonatomic, strong) NSColor *borderHoverColor;
@property (nonatomic, strong) NSColor *borderHighlightColor;
@property (nonatomic, strong) NSColor *borderSelectedColor;

@property (nonatomic, strong) NSColor *normalColor;
@property (nonatomic, strong) NSColor *hoverColor;
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, strong) NSColor *selectedColor;

@property (nonatomic, strong) NSImage *normalImage;
@property (nonatomic, strong) NSImage *hoverImage;
@property (nonatomic, strong) NSImage *highlightImage;
@property (nonatomic, strong) NSImage *selectedImage;

@property (nonatomic, strong) NSColor *backgroundNormalColor;
@property (nonatomic, strong) NSColor *backgroundHoverColor;
@property (nonatomic, strong) NSColor *backgroundHighlightColor;
@property (nonatomic, strong) NSColor *backgroundSelectedColor;

@end
