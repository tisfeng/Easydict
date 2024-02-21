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
#import "NSObject+EZDarkMode.h"
#import "EZBaseQueryWindow.h"
#import "EZConfiguration.h"
#import "Easydict-Swift.h"
#import "EZPreferencesWindowController.h"

@interface EZTitlebar ()

@property (nonatomic, strong) NSStackView *stackView;

@end

@implementation EZTitlebar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
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
    
    [self setupSettingButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConstraints) name:EZQuickLinkButtonUpdateNotification object:nil];
    
}

- (void)setupSettingButton {
    EZOpenLinkButton *settingButton = [[EZOpenLinkButton alloc] init];
    settingButton.contentTintColor = [NSColor clearColor];
    NSImage *image = [NSImage imageWithSystemSymbolName:@"list.bullet" accessibilityDescription:nil];
    self.settingButton = settingButton;
    settingButton.clickBlock = nil;
    
    NSColor *normalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *normalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];
    
    [settingButton excuteLight:^(EZHoverButton *button) {
        button.image = image;
        button.contentTintColor = normalLightTintColor;
    } dark:^(EZHoverButton *button) {
        button.image = image;
        button.contentTintColor = normalDarkTintColor;
    }];
    
    mm_weakify(self);
    [settingButton setMouseUpBlock:^(EZButton *_Nonnull button) {
//        NSLog(@"settingButton mouse up, state: %ld", button.buttonState);
        mm_strongify(self);
        [self showMenu];
        
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
    
    for (NSView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [self.stackView removeFromSuperview];
    
    self.stackView = [[NSStackView alloc] init];
    self.stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.stackView.spacing = kButtonPadding_4;
    self.stackView.alignment = NSLayoutAttributeCenterY;
    [self addSubview:self.stackView];
    
    CGFloat quickLinkButtonTopOffset = EZTitlebarHeight_28 - kButtonWidth_24;
    CGFloat quickLinkButtonRightOffset = 12;
    
    [self.stackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(quickLinkButtonTopOffset);
        make.right.equalTo(self).offset(-quickLinkButtonRightOffset);
    }];
    
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
        [self.stackView insertArrangedSubview:appleDictButton atIndex:0];
    }
    
    // Eudic
    if (Configuration.shared.showEudicQuickLink) {
        EZOpenLinkButton *eudicButton = [[EZOpenLinkButton alloc] init];
        
        // !!!: Note that some applications have multiple channel versions. Ref: https://github.com/tisfeng/Raycast-Easydict/issues/16
        BOOL installedEudic = [self checkInstalledApp:@[@"com.eusoft.freeeudic", @"com.eusoft.eudic"]];
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
            [self.stackView insertArrangedSubview:eudicButton atIndex:0];
        }
    }
    
    [self.settingButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(buttonSize);
    }];
    [self.stackView addArrangedSubview:self.settingButton];
    
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

- (void)showMenu {
    NSMenu * menu = [[NSMenu alloc]initWithTitle:@"Menu"];
    NSMenuItem * item1 = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"automatically_remove_code_comment_symbols", nil) action:@selector(clickAutomaticallyRemoveCodeCommentSymbols) keyEquivalent:@""];
    item1.target = self;
    if (Configuration.shared.automaticallyRemoveCodeCommentSymbols) {
        item1.state = NSControlStateValueOn;
    }
    
    NSMenuItem * item2 = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"automatic_word_segmentation", nil) action:@selector(clickAutomaticWordSegmentation) keyEquivalent:@""];
    item2.target = self;
    if (Configuration.shared.automaticWordSegmentation) {
        item2.state = NSControlStateValueOn;
    }
    
    NSMenuItem * item3 = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"go_to_settings", nil) action:@selector(goToSettings) keyEquivalent:@""];
    item3.target = self;
    
    [menu addItem:item1];
    [menu addItem:item2];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:item3];
    
    [menu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
}

- (void)clickAutomaticallyRemoveCodeCommentSymbols {
    Configuration.shared.automaticallyRemoveCodeCommentSymbols = !Configuration.shared.automaticallyRemoveCodeCommentSymbols;
}

- (void)clickAutomaticWordSegmentation {
    Configuration.shared.automaticWordSegmentation = !Configuration.shared.automaticWordSegmentation;
}

- (void)goToSettings {
    [EZPreferencesWindowController.shared show];
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
