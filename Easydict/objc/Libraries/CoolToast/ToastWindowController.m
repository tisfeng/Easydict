//
//  ToastWindowController.m
//  CoolToast
//
//  Created by Socoolby on 2019/6/28.
//  Copyright © 2019 Socoolby. All rights reserved.
//

#import "ToastWindowController.h"
#import "CTScreen.h"
#import <QuartzCore/QuartzCore.h>
#import "CTCommon.h"

static NSMutableArray<ToastWindowController *> *toastWindows;

@interface ToastWindowController () <NSAnimationDelegate>

@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet NSImageView *iconImageView;
@property (weak) IBOutlet NSLayoutConstraint *messageLabelLeadingConstraint;
@property (weak) IBOutlet NSLayoutConstraint *containerViewWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;
@property (weak) IBOutlet NSLayoutConstraint *containerViewLeadingConstraint;
@property (weak) IBOutlet NSLayoutConstraint *containerTopConstraint;
@property (weak) IBOutlet NSLayoutConstraint *messageTextFieldTrailingConstraint;
@property (weak) IBOutlet NSLayoutConstraint *messageTextFieldLeadingConstraint;
@property (weak) IBOutlet NSLayoutConstraint *iconImageLeadingConstraint;

@end

@implementation ToastWindowController

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _leftOffset = 50;
        _topOffset = 55;
        _rightOffset = 20;
        _bottomOffset = 20;
        
        _maxWidth = 800;
        _minWidth = 50;
        _minHeight = 60;
        _toastPostion = CTPositionTop | CTPositionRight;
        _backgroundColor = [NSColor clearColor];
        _imageMarginLeft = 10;
        _labelMargin = 30;
        
        _conerRadius = 10;
        _autoDismiss = YES;
        _autoDismissTimeInSecond = 2;
        _animater = CTAnimaterFade;
        _animaterTimeSecond = 0.5;
        _textFont = [NSFont systemFontOfSize:15];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

+ (id)getToastWindow {
    if (toastWindows == nil)
        toastWindows = [NSMutableArray new];
    ToastWindowController *toastWindow = [[ToastWindowController alloc] initWithWindowNibName:@"ToastWindowController"];
    [toastWindows addObject:toastWindow];
    return toastWindow;
}

- (NSPoint)getContainerPointWithWidth:(NSUInteger)width height:(NSUInteger)height currentScreen:(NSScreen *)currentScreen {
    NSInteger x = 0;
    NSInteger y = 0;
    NSRect mainScreenFrame = [CTScreen frameForScreen:currentScreen];
    if (self.toastPostion == CTPositionCenter) {
        y = (mainScreenFrame.size.height - height) / 2;
        x = (mainScreenFrame.size.width - width) / 2;
        return NSMakePoint(x, y);
    }
    if ((self.toastPostion & CTPositionLeft) == CTPositionLeft) {
        x = self.leftOffset;
    } else if ((self.toastPostion & CTPositionRight) == CTPositionRight) {
        x = mainScreenFrame.size.width - self.rightOffset - width;
    }
    if ((self.toastPostion & CTPositionTop) == CTPositionTop) {
        y = self.topOffset;
    } else if ((self.toastPostion & CTPositionBottom) == CTPositionBottom) {
        y = mainScreenFrame.size.height - self.bottomOffset - height;
    }
    if (self.toastPostion == CTPositionMouse) {
        NSPoint mousePoint = [self.window mouseLocationOutsideOfEventStream];
        x = mousePoint.x;
        y = mainScreenFrame.size.height - mousePoint.y;
        if (x + width > mainScreenFrame.size.width)
            x = x - width;
        if (y + height > mainScreenFrame.size.height)
            y = y - height;
        if (y < 0)
            y = 0;
        if (x < 0)
            x = 0;
    }
    return NSMakePoint(x, y);
}

- (void)animationDidEnd:(NSAnimation *)animation {
}

- (IBAction)onContainerDoubleClick:(id)sender {
    if (!self.autoDismiss)
        [self dismissWithAnimator];
    if (self.delegate != nil)
        [self.delegate onCoolToastClick:self];
}

- (void)showCoolToast:(NSString *)message {
    [self.window setBackgroundColor:self.backgroundColor];
    NSScreen *focusedScreen = [CTScreen getCurrentScreen];
    [self.window setLevel:NSPopUpMenuWindowLevel];
    self.messageLabel.stringValue = message;
    self.containerView.wantsLayer = YES;
    self.iconImageLeadingConstraint.constant = _imageMarginLeft;
    NSClickGestureRecognizer *tap = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerDoubleClick:)];
    tap.numberOfClicksRequired = 2;
    [self.containerView addGestureRecognizer:tap];
    
    self.containerView.layer.cornerRadius = self.conerRadius;
    if (self.textColor == nil){
        self.messageLabel.textColor = NSColor.whiteColor;
    }
    else
        self.messageLabel.textColor = self.textColor;
    if (self.toastBackgroundColor == nil) {
        CGFloat r = 49.0 / 255.0;
        CGFloat g = 49.0 / 255.0;
        CGFloat b = 49.0 / 255.0;
        CGFloat a = 1.0;
        NSColor *color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
        self.containerView.layer.backgroundColor = color.CGColor;
    }
    else {
        self.containerView.layer.backgroundColor = self.toastBackgroundColor.CGColor;
    }
    
    [self.window setContentSize:NSMakeSize(focusedScreen.visibleFrame.size.width, focusedScreen.frame.size.height)];
    [self.window setFrameOrigin:NSMakePoint(focusedScreen.visibleFrame.origin.x, focusedScreen.visibleFrame.origin.y)];
    [self.messageLabel setFont:self.textFont];
    CGFloat labelMargin = self.labelMargin;
    if (self.hiddenIcon)
        self.iconImageView.hidden = YES;
    else {
        self.messageLabelLeadingConstraint.constant = self.iconImageView.frame.size.width + _imageMarginLeft;
        if (self.iconImage == nil)
            self.iconImageCell.image = [NSApplication sharedApplication].applicationIconImage;
        else
            self.iconImageCell.image = self.iconImage;
    }
    
    [self.containerView needsLayout];
    
    NSInteger iconWidth = self.iconImageView.frame.size.width;
    if (self.hiddenIcon) {
        iconWidth = 0;
    }
    
    NSInteger labelMaxWidth = self.maxWidth - labelMargin * 2 - (self.hiddenIcon ? 0 : iconWidth + _imageMarginLeft);
    NSInteger labelWidth = [CTCommon calculateFont:message withFont:self.messageLabel.font].width;
    int lineCount = [CTCommon lineCountForText:message font:self.messageLabel.font withinWidth:labelMaxWidth];
    int labelHeight = _minHeight;
    if (lineCount > 2) {
        labelHeight = _minHeight + (lineCount - 2) * self.messageLabel.font.boundingRectForFont.size.height;
        labelWidth = labelMaxWidth;
    }
    NSInteger windowWidth = labelWidth + iconWidth + labelMargin * 2 + _imageMarginLeft;
    if (windowWidth < _minWidth)
        windowWidth = _minWidth;
    NSPoint windowPoint = [self getContainerPointWithWidth:windowWidth height:labelHeight currentScreen:focusedScreen];
    
    self.containerViewWidthConstraint.constant = windowWidth;
    self.containerViewHeightConstraint.constant = labelHeight;
    self.containerViewLeadingConstraint.constant = windowPoint.x;
    self.messageTextFieldLeadingConstraint.constant = windowWidth - labelWidth - labelWidth - (self.hiddenIcon ? 0 : _imageMarginLeft * 2 + self.iconImageView.frame.size.width);
    self.messageLabelLeadingConstraint.constant = labelMargin;
    self.containerTopConstraint.constant = windowPoint.y;
    [self.window makeKeyAndOrderFront:nil];
    if (self.autoDismiss) {
        [CTCommon delayToRunWithSecond:self.autoDismissTimeInSecond Block:^{
            [self dismissWithAnimator];
        }];
    }
    [self showWithAnimator];
}

- (void)showWithAnimator {
    if (self.animater == CTAnimaterNone)
        return;
    if (self.animater == CTAnimaterFade) {
        [self.containerView setAlphaValue:0.0];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
            [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
            [[self.containerView animator] setAlphaValue:1.0];
        } completionHandler:^{
        }];
        return;
    } else if (self.animater == CTAnimaterScale) {
        NSRect originFrame = self.containerView.frame;
        int width = self.containerViewWidthConstraint.constant;
        int height = self.containerViewHeightConstraint.constant;
        self.containerViewWidthConstraint.constant = 0;
        self.containerViewHeightConstraint.constant = 0;
        self.containerView.frame = NSMakeRect(originFrame.origin.x + originFrame.size.width / 2, originFrame.origin.y + originFrame.size.height / 2, 0, 0);
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
            [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
            [[self.containerViewHeightConstraint animator] setConstant:height];
            [[self.containerViewWidthConstraint animator] setConstant:width];
            [[self.containerView animator] setFrame:originFrame];
        } completionHandler:^{
        }];
        return;
    }
    NSRect originFrame = self.containerView.frame;
    NSRect transimiteFrame = self.containerView.frame;
    if (self.animater == CTAnimaterTranslateFromLeft) {
        transimiteFrame = NSMakeRect(0 - originFrame.size.width, originFrame.origin.y, originFrame.size.width, originFrame.size.height);
    } else if (self.animater == CTAnimaterTranslateFromTop)
        transimiteFrame = NSMakeRect(originFrame.origin.x, self.window.frame.size.height + originFrame.size.height, originFrame.size.width, originFrame.size.height);
    else if (self.animater == CTAnimaterTranslateFromRight)
        transimiteFrame = NSMakeRect(self.window.frame.size.width + originFrame.size.width, originFrame.origin.y, originFrame.size.width, originFrame.size.height);
    else if (self.animater == CTAnimaterTranslateFromBottom)
        transimiteFrame = NSMakeRect(originFrame.origin.x, 0 - originFrame.size.height, originFrame.size.width, originFrame.size.height);
    
    self.containerView.frame = transimiteFrame;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
        [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
        [[self.containerView animator] setFrame:originFrame];
    } completionHandler:^{
    }];
}

- (void)dismiss {
    [self.window close];
    if (self.delegate != nil)
        [self.delegate onCoolToastDismiss:self];
    [toastWindows removeObject:self];
}

- (void)dismissWithAnimator {
    if (self.animater == CTAnimaterNone) {
        [self dismiss];
        return;
    }
    if (self.animater == CTAnimaterFade) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
            [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
            [[self.containerView animator] setAlphaValue:0.0];
        } completionHandler:^{
            [self dismiss];
        }];
        return;
    } else if (self.animater == CTAnimaterScale) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
            [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
            [[self.containerViewHeightConstraint animator] setConstant:0];
            [[self.containerViewWidthConstraint animator] setConstant:0];
        } completionHandler:^{
            [self dismiss];
        }];
        return;
    }
    NSRect originFrame = self.containerView.frame;
    NSRect transimiteFrame = self.containerView.frame;
    if (self.animater == CTAnimaterTranslateFromLeft) {
        transimiteFrame = NSMakeRect(0 - originFrame.size.width, originFrame.origin.y, originFrame.size.width, originFrame.size.height);
    } else if (self.animater == CTAnimaterTranslateFromTop)
        transimiteFrame = NSMakeRect(originFrame.origin.x, self.window.frame.size.height + originFrame.size.height, originFrame.size.width, originFrame.size.height);
    else if (self.animater == CTAnimaterTranslateFromRight)
        transimiteFrame = NSMakeRect(self.window.frame.size.width + originFrame.size.width, originFrame.origin.y, originFrame.size.width, originFrame.size.height);
    else if (self.animater == CTAnimaterTranslateFromBottom)
        transimiteFrame = NSMakeRect(originFrame.origin.x, 0 - originFrame.size.height, originFrame.size.width, originFrame.size.height);
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
        [[NSAnimationContext currentContext] setDuration:self.animaterTimeSecond];
        [[self.containerView animator] setFrame:transimiteFrame];
    } completionHandler:^{
        [self dismiss];
    }];
}

@end
