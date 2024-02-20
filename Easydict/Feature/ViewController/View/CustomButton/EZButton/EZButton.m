//
//  EZButton.m
//  EZButton-Demo
//
//  Created by tisfeng on 2022/11/8.
//

#import "EZButton.h"

@interface EZButton ()

@property (nonatomic, assign) BOOL hover;
@property (nonatomic, assign) BOOL mouseUp;

@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end

@implementation EZButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInitialize];
    }
    return self;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    [super viewWillMoveToSuperview:newSuperview];
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect originRect = self.bounds;
    self.bounds = NSInsetRect(originRect, self.edgeInsets.left + self.edgeInsets.right, self.edgeInsets.top + self.edgeInsets.bottom);
    [super drawRect:dirtyRect];
    self.bounds = originRect;
}

#pragma mark - Mouse Actions

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    
    self.buttonState = EZButtonNormalState;
    
    if (self.trackingArea) {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    NSTrackingAreaOptions options =
    NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited |
    NSTrackingEnabledDuringMouseDrag | NSTrackingActiveAlways;
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:CGRectZero
                                                     options:options
                                                       owner:self
                                                    userInfo:nil];
    
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    //        NSLog(@"mouseEntered");
    
    if (!self.enabled) {
        return;
    }
    
    if (self.mouseEnterBlock) {
        self.mouseEnterBlock(self);
    }
    
    // !!!: Set buttonState should be placed at the end, this will update button UI display.
    self.hover = YES;
    self.buttonState = EZButtonHoverState;
}

- (void)mouseExited:(NSEvent *)event {
    //        NSLog(@"mouseExited");
    
    if (!self.enabled) {
        return;
    }
    
    if (self.mouseExitedBlock) {
        self.mouseExitedBlock(self);
    }
    
    self.hover = NO;
    if (self.selected) {
        [self setButtonState:EZButtonSelectedState];
    } else {
        [self setButtonState:EZButtonNormalState];
    }
}

- (void)mouseDown:(NSEvent *)event {
    //    NSLog(@"mouseDown");
    
    if (!self.enabled) {
        return;
    }
    
    if (self.mouseDownBlock) {
        self.mouseDownBlock(self);
    }
    
    self.mouseUp = NO;
    if (self.enabled && self.hover) {
        self.buttonState = EZButtonHighlightState;
    }
}

- (void)mouseUp:(NSEvent *)event {
    //    NSLog(@"mouseUp");
    
    if (!self.enabled) {
        return;
    }
    
    if (self.mouseUpBlock) {
        self.mouseUpBlock(self);
    }
    
    self.mouseUp = YES;
    if (self.enabled && self.hover) {
        if (self.canSelected) {
            self.selected = !self.selected;
        }
        self.buttonState = EZButtonHoverState;
        
        //        NSLog(@"send action");
        
        NSString *selString = NSStringFromSelector(self.action);
        if ([selString hasSuffix:@":"]) {
            [self.target performSelector:self.action
                              withObject:self
                              afterDelay:0.f];
        } else {
            [self.target performSelector:self.action withObject:nil afterDelay:0.f];
        }
    }
}

- (void)mouseDragged:(NSEvent *)event {
    //    NSLog(@"mouseDragged");
    
    if (!self.enabled) {
        return;
    }
    
    CGPoint point = event.locationInWindow;
    CGPoint innerPoint = [self convertPoint:point fromView:self.window.contentView];
    if (CGRectContainsPoint(self.bounds, innerPoint)) {
        self.hover = YES;
        [self setButtonState:EZButtonHoverState];
    } else {
        //        NSLog(@"mouse drag out");
        
        self.hover = NO;
        if (self.canSelected) {
            self.buttonState =
            self.selected ? EZButtonSelectedState : EZButtonNormalState;
        } else {
            [self setButtonState:EZButtonNormalState];
        }
    }
}


#pragma mark - Private Methods

- (void)commonInitialize {
    //    self.backgroundHighlightColor = NSColor.highlightColor;
    //    self.backgroundSelectedColor = NSColor.selectedTextBackgroundColor;
    
    [self initializeUI];
    
    [self setTarget:self];
    [self setAction:@selector(click:)];
}

- (void)initializeUI {
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
    [self setButtonType:NSButtonTypeMomentaryPushIn];
    self.bezelStyle = NSBezelStyleTexturedSquare;
    self.bordered = NO;
    self.imageScaling = NSImageScaleProportionallyDown;
    
    [self setupTitle];
}

- (void)setupTitle {
    [self setTitle:self.normalTitle
        titleColor:self.titleColor
         titleFont:self.titleFont];
}

- (void)setTitle:(NSString *)title
      titleColor:(NSColor *)titleColor
       titleFont:(NSFont *)titleFont {
    NSAttributedString *attributedTitle = self.attributedTitle;
    if (title.length) {
        attributedTitle = [[NSAttributedString alloc] initWithString:title];
    }
    NSMutableAttributedString *attributedString =
    [[NSMutableAttributedString alloc]
     initWithAttributedString:attributedTitle];
    if (attributedString.length == 0) {
        return;
    }
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (titleColor) {
        attributes[NSForegroundColorAttributeName] = titleColor;
    }
    if (titleFont) {
        attributes[NSFontAttributeName] = titleFont;
    }
    NSRange titleRange = NSMakeRange(0, attributedString.length);
    [attributedString addAttributes:attributes range:titleRange];
    
    self.attributedTitle = attributedString;
}

- (void)updateButtonApperaceWithState:(EZButtonState)state {
    //        NSLog(@"button state: %@", @(state));
    
    CGFloat cornerRadius = 0.f;
    CGFloat borderWidth = 0.f;
    NSColor *borderColor = nil;
    
    NSString *title = nil;
    NSColor *titleColor = nil;
    NSFont *titleFont = nil;
    
    NSColor *backgroundColor = nil;
    NSImage *image = nil;
    
    switch (state) {
        case EZButtonNormalState: {
            cornerRadius = self.cornerRadius;
            borderWidth = self.borderWidth;
            borderColor = self.borderColor;
            title = self.normalTitle;
            titleColor = self.titleColor;
            titleFont = self.titleFont;
            backgroundColor = self.backgroundColor;
            image = self.normalImage;
            break;
        }
        case EZButtonHoverState: {
            cornerRadius = self.cornerHoverRadius;
            borderWidth = self.borderHoverWidth;
            borderColor = self.borderHoverColor;
            title = self.hoverTitle;
            titleColor = self.titleHoverColor;
            titleFont = self.titleHoverFont;
            backgroundColor = self.backgroundHoverColor;
            image = self.hoverImage;
        } break;
        case EZButtonHighlightState: {
            cornerRadius = self.cornerHighlightRadius;
            borderWidth = self.borderHighlightWidth;
            borderColor = self.borderHighlightColor;
            title = self.highlightTitle;
            titleColor = self.titleHighlightColor;
            titleFont = self.titleHighlightFont;
            backgroundColor = self.backgroundHighlightColor;
            image = self.highlightImage;
        } break;
        case EZButtonSelectedState: {
            cornerRadius = self.cornerSelectedRadius;
            borderWidth = self.borderSelectedWidth;
            borderColor = self.borderSelectedColor;
            title = self.selectedTitle;
            titleColor = self.titleSelectedColor;
            titleFont = self.titleSelectedFont;
            backgroundColor = self.backgroundSelectedColor;
            image = self.selectedImage;
        } break;
    }
    if (image != nil) {
        self.image = image;
    }
    
    [self setTitle:title titleColor:titleColor titleFont:titleFont];
    
    self.layer.cornerRadius = cornerRadius;
    self.layer.borderWidth = borderWidth;
    self.layer.borderColor = borderColor.CGColor;
    self.layer.backgroundColor = backgroundColor.CGColor;
}


#pragma mark - Setter

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    
    if (!_cornerHoverRadius) {
        _cornerHoverRadius = cornerRadius;
    }
    if (!_cornerHighlightRadius) {
        _cornerHighlightRadius = cornerRadius;
    }
    if (!_cornerSelectedRadius) {
        _cornerSelectedRadius = cornerRadius;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    
    if (!_borderHoverWidth) {
        _borderHoverWidth = borderWidth;
    }
    if (!_borderHighlightWidth) {
        _borderHighlightWidth = borderWidth;
    }
    if (!_borderSelectedWidth) {
        _borderSelectedWidth = borderWidth;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setBorderColor:(NSColor *)borderColor {
    _borderColor = borderColor;
    
    if (!_borderHoverColor) {
        _borderHoverColor = borderColor;
    }
    if (!_borderHighlightColor) {
        _borderHighlightColor = borderColor;
    }
    if (!_borderSelectedColor) {
        _borderSelectedColor = borderColor;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setNormalTitle:(NSString *)normalTitle {
    _normalTitle = normalTitle;
    
    if (!_hoverTitle) {
        _hoverTitle = normalTitle;
    }
    if (!_highlightTitle) {
        _highlightTitle = normalTitle;
    }
    if (!_selectedTitle) {
        _selectedTitle = normalTitle;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setTitleColor:(NSColor *)titleColor {
    _titleColor = titleColor;
    
    if (!_titleHoverColor) {
        _titleHoverColor = titleColor;
    }
    if (!_titleHighlightColor) {
        _titleHighlightColor = titleColor;
    }
    if (!_titleSelectedColor) {
        _titleSelectedColor = titleColor;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setTitleFont:(NSFont *)titleFont {
    _titleFont = titleFont;
    
    if (!_titleHoverFont) {
        _titleHoverFont = titleFont;
    }
    if (!_titleHighlightFont) {
        _titleHighlightFont = titleFont;
    }
    if (!_titleSelectedFont) {
        _titleSelectedFont = titleFont;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setNormalImage:(NSImage *)normalImage {
    _normalImage = normalImage;
    
    if (!_hoverImage) {
        _hoverImage = normalImage;
    }
    if (!_highlightImage) {
        _highlightImage = normalImage;
    }
    if (!_selectedImage) {
        _selectedImage = normalImage;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    
    if (!_backgroundHoverColor) {
        _backgroundHoverColor = backgroundColor;
    }
    if (!_backgroundHighlightColor) {
        _backgroundHighlightColor = backgroundColor;
    }
    if (!_backgroundSelectedColor) {
        _backgroundSelectedColor = backgroundColor;
    }
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setCanSelected:(BOOL)canSelected {
    _canSelected = canSelected;
    
    [self updateButtonApperaceWithState:self.buttonState];
}

- (void)setButtonState:(EZButtonState)state {
    //    NSLog(@"set state: %lu", (unsigned long)state);
    
    _buttonState = state;
    
    [self updateButtonApperaceWithState:state];
}

- (void)setAttrTitle:(NSAttributedString *)attrTitle {
    _attrTitle = attrTitle;
    
    self.attributedTitle = attrTitle;
    
    [self updateButtonApperaceWithState:self.buttonState];
}

#pragma mark - Rewrite
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    self.normalTitle = title;
    [self setupTitle];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    
    self.titleFont = font;
    [self setupTitle];
}

- (void)setImage:(NSImage *)image {
    [super setImage:image];
    
    // We don't want to show up the default button title when an image is set.
    NSString *defaultButtonTitle = NSButton.new.title;
    if ([self.title isEqualToString:defaultButtonTitle]) {
        self.title = @"";
    }
}


#pragma mark - Click Action

- (void)click:(EZButton *)button {
    //    NSLog(@"click");
    
    if (self.clickBlock) {
        self.clickBlock(self);
    }
}

@end
