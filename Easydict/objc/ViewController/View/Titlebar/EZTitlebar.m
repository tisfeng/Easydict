//
//  EZTitlebar.m
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTitlebar.h"
#import "EZTitleBarMoveView.h"
#import "NSObject+EZWindowType.h"
#import "NSImage+EZResize.h"
#import "NSImage+EZSymbolmage.h"
#import "NSObject+EZDarkMode.h"
#import "EZBaseQueryWindow.h"
#import "EZConfiguration.h"
#import "EZPreferencesWindowController.h"

typedef NS_ENUM(NSInteger, EZTitlebarButtonType) {
    EZTitlebarButtonTypePin = 0,
    EZTitlebarButtonTypeGoogle,
    EZTitlebarButtonTypeAppleDic,
    EZTitlebarButtonTypeEudicDic,
};

@interface EZTitlebar ()

@property (nonatomic, strong) NSStackView *stackView;
@property (nonatomic, strong) NSMenu *quickActionMenu;

@property (nonatomic, assign) CGSize buttonSize;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign) CGFloat buttonPadding;

@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGFloat imageWidth;

@end

@implementation EZTitlebar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)updateButtonsToolTip {
    [self updateConstraints];
}

- (void)setup {
    self.buttonWidth = 24;
    self.imageWidth = 20;
    self.buttonPadding = 4;
    
    self.buttonSize = CGSizeMake(self.buttonWidth, self.buttonWidth);
    self.imageSize = CGSizeMake(self.imageWidth, self.imageWidth);
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(updateConstraints) name:EZQuickLinkButtonUpdateNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(updateConstraints) name:NSNotification.languagePreferenceChanged object:nil];
}


- (void)updateConstraints {
    // Remove and dealloc all views to refresh UI.
    for (NSView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    // Reset buttons to update toolTip.
    _quickActionMenu = nil;
    _quickActionButton = nil;
    _googleButton = nil;
    _eudicButton = nil;
    _appleDictionaryButton = nil;
    _stackView = nil;
    
    [self addSubview:self.pinButton];
    [self updatePinButton];
    [self quickActionMenu];

    CGFloat margin = EZHorizontalCellSpacing_10;
    CGFloat topOffset = EZTitlebarHeight_28 - self.buttonWidth;
    
    [self.pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(self.buttonWidth);
        make.left.inset(margin);
        make.top.equalTo(self).offset(topOffset);
    }];
    
    [self addSubview:self.stackView];
    [self.stackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(topOffset);
        make.right.equalTo(self).offset(-margin);
    }];
    
    if (Configuration.shared.showQuickActionButton) {
        [self.stackView addArrangedSubview:self.quickActionButton];
    }
    
    // Google
    if (Configuration.shared.showGoogleQuickLink) {
        [self.stackView addArrangedSubview:self.googleButton];
    }
    
    // Apple Dictionary
    if (Configuration.shared.showAppleDictionaryQuickLink) {
        [self.stackView addArrangedSubview:self.appleDictionaryButton];
    }
    
    // Eudic
    if (Configuration.shared.showEudicQuickLink) {
        // !!!: Note that some applications have multiple channel versions. Refer: https://github.com/tisfeng/Raycast-Easydict/issues/16
        BOOL installedEudic = [self checkInstalledApp:@[ @"com.eusoft.freeeudic", @"com.eusoft.eudic" ]];
        if (installedEudic) {
            [self.stackView addArrangedSubview:self.eudicButton];
        }
    }
    
    [super updateConstraints];
}


#pragma mark - Actions

- (void)replaceNewlineWithSpace {
    _menuActionBlock(EZTitlebarQuickActionReplaceNewlineWithSpace);
}

- (void)removeCodeCommentSymbols {
    _menuActionBlock(EZTitlebarQuickActionRemoveCommentBlockSymbols);
}

- (void)splitWords {
    _menuActionBlock(EZTitlebarQuickActionWordsSegmentation);
}

- (void)goToSettings {
    if ([[Configuration shared] enableBetaNewApp]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EZOpenSettingsNotification object:nil];
    } else {
        [EZPreferencesWindowController.shared show];
    }
}

#pragma mark - Getter && Setter

- (EZOpenLinkButton *)pinButton {
    if (!_pinButton) {
        EZOpenLinkButton *pinButton = [[EZOpenLinkButton alloc] init];
        _pinButton = pinButton;
        
        pinButton.contentTintColor = [NSColor clearColor];
        pinButton.clickBlock = nil;
        self.pin = NO;
        
        mm_weakify(self);
        [pinButton setMouseDownBlock:^(EZButton *_Nonnull button) {
            //  NSLog(@"pin mouse down, state: %ld", button.buttonState);
            mm_strongify(self);
            self.pin = !self.pin;
        }];
        
        [pinButton setMouseUpBlock:^(EZButton *_Nonnull button) {
            //  NSLog(@"pin mouse up, state: %ld", button.buttonState);
            mm_strongify(self);
            BOOL oldPin = !self.pin;
            
            // This means clicked pin button.
            if (button.state == EZButtonHoverState) {
                self.pin = !oldPin;
            } else if (button.buttonState == EZButtonNormalState) {
                self.pin = oldPin;
            }
        }];
    }
    return _pinButton;
}

- (NSStackView *)stackView {
    if (!_stackView) {
        _stackView = [[NSStackView alloc] init];
        _stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        _stackView.spacing = self.buttonPadding;
        _stackView.alignment = NSLayoutAttributeCenterY;
        _stackView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionRightToLeft;
    }
    return _stackView;
}

- (NSMenu *)quickActionMenu {
    if (!_quickActionMenu) {
        NSMenu *menu = [NSMenu new];
        NSArray *menuSections = @[
            @[
                @{
                    @"title" : @"replace_newline_with_space",
                    @"action" : NSStringFromSelector(@selector(replaceNewlineWithSpace))
                },
                @{
                    @"title" : @"remove_code_comment_symbols",
                    @"action" : NSStringFromSelector(@selector(removeCodeCommentSymbols))
                },
                @{
                    @"title" : @"split_words",
                    @"action" : NSStringFromSelector(@selector(splitWords))
                }
            ],
            @[
                @{
                    @"title" : @"go_to_settings",
                    @"action" : NSStringFromSelector(@selector(goToSettings))
                }
            ]
            /**
             Just fix localization warning.
             
             NSLocalizedString(@"replace_newline_with_space", nil);
             NSLocalizedString(@"remove_code_comment_symbols", nil);
             NSLocalizedString(@"split_words", nil);
             */
        ];
        
        for (NSArray *section in menuSections) {
            for (NSDictionary *itemDict in section) {
                NSString *titleKey = itemDict[@"title"];
                NSString *title = NSLocalizedString(titleKey, nil);
                SEL action = NSSelectorFromString(itemDict[@"action"]);
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
                menuItem.target = self;
                [menu addItem:menuItem];
            }
            // Add separatorItem
            if (section != menuSections.lastObject) {
                [menu addItem:[NSMenuItem separatorItem]];
            }
        }
        _quickActionMenu = menu;
    }
    return _quickActionMenu;
}

- (EZOpenLinkButton *)quickActionButton {
    if (!_quickActionButton) {
        EZOpenLinkButton *quickActionButton = [[EZOpenLinkButton alloc] init];
        _quickActionButton = quickActionButton;
        NSImage *image = [[NSImage imageWithSystemSymbolName:@"switch.2" accessibilityDescription:nil] imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithScale:NSImageSymbolScaleLarge]];
        image = [NSImage ez_imageWithSymbolName:@"switch.2"];
        quickActionButton.image = image;
        quickActionButton.toolTip = NSLocalizedString(@"quick_action", nil);
        
        mm_weakify(self);
        [quickActionButton setClickBlock:^(EZButton *_Nonnull button) {
            mm_strongify(self);
            [self.quickActionMenu popUpBelowView:self.quickActionButton];
        }];
        
        NSColor *lightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
        NSColor *darkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];
        CGSize imageSize = CGSizeMake(20, 20);
        
        [quickActionButton excuteLight:^(EZButton *button) {
            button.image = [[image imageWithTintColor:lightTintColor] resizeToSize:imageSize];
        } dark:^(EZButton *button) {
            button.image = [[image imageWithTintColor:darkTintColor] resizeToSize:imageSize];
        }];
        
        [quickActionButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(24);
        }];
    }
    return _quickActionButton;
}

- (EZOpenLinkButton *)googleButton {
    if (!_googleButton) {
        EZOpenLinkButton *googleButton = [[EZOpenLinkButton alloc] init];
        _googleButton = googleButton;
        
        googleButton.link = EZGoogleWebSearchURL;
        googleButton.image = [[NSImage imageNamed:@"google_icon"] resizeToSize:self.imageSize];
        googleButton.toolTip = [self toolTipStrWithButtonType:EZTitlebarButtonTypeGoogle];
        googleButton.contentTintColor = NSColor.clearColor;
        
        [googleButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.buttonSize);
        }];
    }
    return _googleButton;
}

- (EZOpenLinkButton *)appleDictionaryButton {
    if (!_appleDictionaryButton) {
        EZOpenLinkButton *appleDictButton = [[EZOpenLinkButton alloc] init];
        _appleDictionaryButton = appleDictButton;
        
        appleDictButton.link = EZAppleDictionaryAppURLScheme;
        appleDictButton.image = [[NSImage imageNamed:EZServiceTypeAppleDictionary] resizeToSize:self.imageSize];
        appleDictButton.toolTip = [self toolTipStrWithButtonType:EZTitlebarButtonTypeAppleDic];
        appleDictButton.contentTintColor = NSColor.clearColor;
        
        [appleDictButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.buttonSize);
        }];
        
    }
    return _appleDictionaryButton;
}

- (EZOpenLinkButton *)eudicButton {
    if (!_eudicButton) {
        EZOpenLinkButton *eudicButton = [[EZOpenLinkButton alloc] init];
        _eudicButton = eudicButton;
        
        eudicButton.link = EZEudicAppURLScheme;
        eudicButton.image = [[NSImage imageNamed:@"Eudic"] resizeToSize:self.imageSize];
        eudicButton.toolTip = [self toolTipStrWithButtonType:EZTitlebarButtonTypeEudicDic];
        eudicButton.contentTintColor = NSColor.clearColor;
        
        [eudicButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.buttonSize);
        }];
    }
    return _eudicButton;
}


- (BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    return window.pin;
}

- (void)setPin:(BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    window.pin = pin;

    [self updatePinButton];
}

#pragma mark -

- (NSString *)toolTipStrWithButtonType:(EZTitlebarButtonType)type {
    NSString *toolTipStr = @"";
    NSString *shortcutStr = @"";
    NSString *hint = @"";
    if (type == EZTitlebarButtonTypePin) {
        shortcutStr = Configuration.shared.pinShortcutString;
        hint = self.pin ? NSLocalizedString(@"unpin", nil) : NSLocalizedString(@"pin", nil);
    } else if (type == EZTitlebarButtonTypeGoogle) {
        shortcutStr = Configuration.shared.googleShortcutString;
        hint = NSLocalizedString(@"open_in_google", nil);
    } else if (type == EZTitlebarButtonTypeAppleDic) {
        shortcutStr = Configuration.shared.appleDictShortcutString;
        hint = NSLocalizedString(@"open_in_apple_dictionary", nil);
    } else if (type == EZTitlebarButtonTypeEudicDic) {
        shortcutStr = Configuration.shared.eudicDictShortcutString;
        hint = NSLocalizedString(@"open_in_eudic", nil);
    }
    if (shortcutStr.length != 0) {
        toolTipStr = [NSString stringWithFormat:@"%@, %@", hint, shortcutStr];
    } else {
        toolTipStr = [NSString stringWithFormat:@"%@", hint];
    }
    return toolTipStr;
}

- (void)updatePinButton {
    self.pinButton.toolTip = [self toolTipStrWithButtonType:EZTitlebarButtonTypePin];
    
    CGFloat imageWidth = 18;
    CGSize imageSize = CGSizeMake(imageWidth, imageWidth);
    
    // Since the system's dark picture mode cannot dynamically follow the mode switch changes, we manually implement dark mode picture coloring.
    NSColor *pinNormalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *pinNormalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];
    
    NSImage *normalLightImage = [[NSImage imageNamed:@"new_pin_normal"] resizeToSize:imageSize];
    normalLightImage = [normalLightImage imageWithTintColor:pinNormalLightTintColor];
    NSImage *normalDarkImage = [normalLightImage imageWithTintColor:pinNormalDarkTintColor];
    
    NSImage *selectedImage = [[NSImage imageNamed:@"new_pin_selected"] resizeToSize:imageSize];
    
    mm_weakify(self);
    [self.pinButton excuteLight:^(EZHoverButton *button) {
        mm_strongify(self)
        NSImage *image = self.pin ? selectedImage : normalLightImage;
        button.image = image;
    } dark:^(EZHoverButton *button) {
        mm_strongify(self)
        NSImage *image = self.pin ? selectedImage : normalDarkImage;
        button.image = image;
    }];
}

/// Check if installed app according to bundle id array
- (BOOL)checkInstalledApp:(NSArray<NSString *> *)bundleIds {
    for (NSString *bundleId in bundleIds) {
        if ([[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleId]) {
            return YES;
        }
    }
    return NO;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
