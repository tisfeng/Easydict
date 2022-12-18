//
//  EZButton.h
//  EZButton-Demo
//
//  Created by tisfeng on 2022/11/8.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZButton : NSButton

typedef NS_ENUM(NSUInteger, EZButtonState) {
    EZButtonNormalState = 0,
    EZButtonHoverState = 1,
    EZButtonHighlightState = 2,
    EZButtonSelectedState = 3
};

@property (nonatomic, assign) BOOL canSelected; // default NO
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) EZButtonState buttonState;

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat cornerHoverRadius;
@property (nonatomic, assign) CGFloat cornerHighlightRadius;
@property (nonatomic, assign) CGFloat cornerSelectedRadius;

@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat borderHoverWidth;
@property (nonatomic, assign) CGFloat borderHighlightWidth;
@property (nonatomic, assign) CGFloat borderSelectedWidth;

@property (nonatomic, strong, nonnull) NSColor *borderColor;
@property (nonatomic, strong, nonnull) NSColor *borderHoverColor;
@property (nonatomic, strong, nonnull) NSColor *borderHighlightColor;
@property (nonatomic, strong, nonnull) NSColor *borderSelectedColor;

@property (nonatomic, copy, nonnull) NSString *normalTitle; // as well as title
@property (nonatomic, copy, nonnull) NSString *hoverTitle;
@property (nonatomic, copy, nonnull) NSString *highlightTitle;
@property (nonatomic, copy, nonnull) NSString *selectedTitle;

@property (nonatomic, strong, nonnull) NSColor *titleColor;
@property (nonatomic, strong, nonnull) NSColor *titleHoverColor;
@property (nonatomic, strong, nonnull) NSColor *titleHighlightColor;
@property (nonatomic, strong, nonnull) NSColor *titleSelectedColor;

@property (nonatomic, strong, nonnull) NSFont *titleFont; // as well as font
@property (nonatomic, strong, nonnull) NSFont *titleHoverFont;
@property (nonatomic, strong, nonnull) NSFont *titleHighlightFont;
@property (nonatomic, strong, nonnull) NSFont *titleSelectedFont;

@property (nonatomic, strong) NSImage *normalImage; // !!!: different from image if need to change image when state changed
@property (nonatomic, strong) NSImage *hoverImage;
@property (nonatomic, strong) NSImage *highlightImage;
@property (nonatomic, strong) NSImage *selectedImage;

@property (nonatomic, strong, nonnull) NSColor *backgroundColor;
@property (nonatomic, strong, nonnull) NSColor *backgroundHoverColor;
@property (nonatomic, strong, nonnull) NSColor *backgroundHighlightColor;
@property (nonatomic, strong, nonnull) NSColor *backgroundSelectedColor;

@property (nonatomic, copy) NSAttributedString *attrTitle;

@property (nonatomic, copy, nullable) void (^clickBlock)(EZButton *button);

@property (nonatomic, copy, nullable) void (^mouseEnterBlock)(EZButton *button);
@property (nonatomic, copy, nullable) void (^mouseExitedBlock)(EZButton *button);
@property (nonatomic, copy, nullable) void (^mouseDownBlock)(EZButton *button);
@property (nonatomic, copy, nullable) void (^mouseUpBlock)(EZButton *button);

@end

NS_ASSUME_NONNULL_END
