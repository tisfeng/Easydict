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
#import "Easydict-Swift.h"
#import "EZPreferencesWindowController.h"

@interface EZTitlebar ()

@property (nonatomic, strong) NSStackView *stackView;
@property (nonatomic, strong) NSMenu *quickActionMenu;

@end

@implementation EZTitlebar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
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

- (void)setup {
    //    EZTitleBarMoveView *moveView = [[EZTitleBarMoveView alloc] init];
    //    moveView.wantsLayer = YES;
    //    moveView.layer.backgroundColor = NSColor.clearColor.CGColor;
    //    [self addSubview:moveView];
    //    [moveView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self);
    //    }];
    
    EZOpenLinkButton *pinButton = [[EZOpenLinkButton alloc] init];
    [self addSubview:pinButton];
    self.pinButton = pinButton;
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
    
    [self setupQuickActionButton];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(updateConstraints) name:EZQuickLinkButtonUpdateNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(updateConstraints) name:NSNotification.languagePreferenceChanged object:nil];
}

- (void)setupQuickActionButton {
    EZOpenLinkButton *quickActionButton = [[EZOpenLinkButton alloc] init];
    NSImage *image = [[NSImage imageWithSystemSymbolName:@"switch.2" accessibilityDescription:nil] imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithScale:NSImageSymbolScaleLarge]];
    image = [NSImage ez_imageWithSymbolName:@"switch.2"];
    quickActionButton.image = image;
    quickActionButton.toolTip = NSLocalizedString(@"quick_action", nil);
    self.quickActionButton = quickActionButton;
    
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

- (void)updateConstraints {
    CGFloat kButtonWidth_24 = 24;
    CGFloat kImagenWidth_20 = 20;
    CGFloat kButtonPadding_4 = 4;
    
    CGSize buttonSize = CGSizeMake(kButtonWidth_24, kButtonWidth_24);
    CGSize imageSize = CGSizeMake(kImagenWidth_20, kImagenWidth_20);
    
    [self.pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        CGFloat pinButtonWidth = 24;
        make.width.height.mas_equalTo(pinButtonWidth);
        make.left.inset(11);
        make.top.equalTo(self).offset(EZTitlebarHeight_28 - pinButtonWidth);
    }];
    
    // Remove and new views to refresh the UI.
    for (NSView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [self.stackView removeFromSuperview];
    self.quickActionMenu = nil;
    
    self.stackView = [[NSStackView alloc] init];
    self.stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.stackView.spacing = kButtonPadding_4;
    self.stackView.alignment = NSLayoutAttributeCenterY;
    self.stackView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionRightToLeft;
    [self addSubview:self.stackView];
    
    CGFloat quickLinkButtonTopOffset = EZTitlebarHeight_28 - kButtonWidth_24;
    CGFloat quickLinkButtonRightOffset = 12;
    
    [self.stackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(quickLinkButtonTopOffset);
        make.right.equalTo(self).offset(-quickLinkButtonRightOffset);
    }];
    
    if (Configuration.shared.showSettingQuickLink) {
        [self.stackView addArrangedSubview:self.quickActionButton];
    }
    
    // Google
    if (Configuration.shared.showGoogleQuickLink) {
        EZOpenLinkButton *googleButton = [[EZOpenLinkButton alloc] init];
        [self addSubview:googleButton];
        self.googleButton = googleButton;
        self.favoriteButton = googleButton;
        
        googleButton.link = EZGoogleWebSearchURL;
        googleButton.image = [[NSImage imageNamed:@"google_icon"] resizeToSize:imageSize];
        googleButton.toolTip = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"open_in_google", nil), @" ⌘+⏎"];
        googleButton.contentTintColor = NSColor.clearColor;
        
        [googleButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
        }];
        
        [self.stackView addArrangedSubview:googleButton];
    }
    
    // Apple Dictionary
    if (Configuration.shared.showAppleDictionaryQuickLink) {
        EZOpenLinkButton *appleDictButton = [[EZOpenLinkButton alloc] init];
        [self addSubview:appleDictButton];
        self.appleDictionaryButton = appleDictButton;
        self.favoriteButton = appleDictButton;
        
        appleDictButton.link = EZAppleDictionaryAppURLScheme;
        appleDictButton.image = [[NSImage imageNamed:EZServiceTypeAppleDictionary] resizeToSize:imageSize];
        appleDictButton.toolTip = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"open_in_apple_dictionary", nil), @"⌘+⇧+D"];
        appleDictButton.contentTintColor = NSColor.clearColor;
        
        [appleDictButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
        }];
        
        [self.stackView addArrangedSubview:appleDictButton];
    }
    
    // Eudic
    if (Configuration.shared.showEudicQuickLink) {
        EZOpenLinkButton *eudicButton = [[EZOpenLinkButton alloc] init];
        
        // !!!: Note that some applications have multiple channel versions. Ref: https://github.com/tisfeng/Raycast-Easydict/issues/16
        BOOL installedEudic = [self checkInstalledApp:@[ @"com.eusoft.freeeudic", @"com.eusoft.eudic" ]];
        eudicButton.hidden = !installedEudic;
        if (installedEudic) {
            [self addSubview:eudicButton];
            self.eudicButton = eudicButton;
            self.favoriteButton = eudicButton;
            
            eudicButton.link = EZEudicAppURLScheme;
            eudicButton.image = [[NSImage imageNamed:@"Eudic"] resizeToSize:imageSize];
            eudicButton.toolTip = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"open_in_eudic", nil), @"⌘+⇧+⏎"];
            eudicButton.contentTintColor = NSColor.clearColor;
            
            [eudicButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(buttonSize);
            }];
            [self.stackView addArrangedSubview:eudicButton];
        }
    }
    
    [super updateConstraints];
}

- (void)updatePinButtonImage {
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

#pragma mark - Actions

- (void)replaceNewlineWithSpace {
    _menuQuickActionBlock(EZTitlebarQuickActionReplaceNewlineWithSpace);
}

- (void)removeCodeCommentSymbols {
    _menuQuickActionBlock(EZTitlebarQuickActionRemoveCommentBlockSymbols);
}

- (void)splitWords {
    _menuQuickActionBlock(EZTitlebarQuickActionWordsSegmentation);
}

- (void)goToSettings {
    if ([[Configuration shared] enableBetaNewApp]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EZOpenSettingsNotification object:nil];
    } else {
        [EZPreferencesWindowController.shared show];
    }
}

#pragma mark - Setter && Getter

- (BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    return window.pin;
}

- (void)setPin:(BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    window.pin = pin;
    NSString *shortcut = @"⌘+P";
    NSString *action = pin ? NSLocalizedString(@"unpin", nil) : NSLocalizedString(@"pin", nil);
    self.pinButton.toolTip = [NSString stringWithFormat:@"%@, %@", action, shortcut];
    
    [self updatePinButtonImage];
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
