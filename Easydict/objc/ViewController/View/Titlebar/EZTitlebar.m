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
#import "Easydict-Swift.h"

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

- (void)setup {
    self.buttonWidth = 24;
    self.imageWidth = 20;
    self.buttonPadding = 4;
    
    self.buttonSize = CGSizeMake(self.buttonWidth, self.buttonWidth);
    self.imageSize = CGSizeMake(self.imageWidth, self.imageWidth);
    
    [self addSubview:self.pinButton];
    [self addSubview:self.favoriteButton];
    [self addSubview:self.stackView];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(updateTitlebar) name:NSNotification.linkButtonUpdated object:nil];
    [defaultCenter addObserver:self selector:@selector(updateTitlebar) name:NSNotification.languagePreferenceChanged object:nil];
    [defaultCenter addObserver:self selector:@selector(updateFavoriteButton) name:NSNotification.serviceHasUpdated object:nil];
}

- (void)updateTitlebar {
    /**
     Fix appcenter issue, seems cannot remove self.subviews 🤔
     
     -[EZTitlebar updateConstraints]
     EZTitlebar.m, line 64
     SIGABRT: *** Collection <__NSArrayM: 0x6000036e45d0> was mutated while being enumerated.
     */
    
    // Remove and dealloc all views to refresh UI.
    
    [_pinButton removeFromSuperview];
    [_favoriteButton removeFromSuperview];
    [_stackView removeFromSuperview];
    _stackView = nil;
    _quickActionButton = nil;
    
    [self updatePinButton];
    [self updateFavoriteButton];
    
    [self addSubview:self.pinButton];
    [self addSubview:self.favoriteButton];
    [self addSubview:self.stackView];
    
    [self setNeedsUpdateConstraints:YES];
}

- (void)updateConstraints {
    CGFloat margin = EZHorizontalCellSpacing_10;
    CGFloat topOffset = EZTitlebarHeight_28 - self.buttonWidth;
    
    [self.pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(self.buttonWidth);
        make.left.inset(margin);
        make.top.equalTo(self).offset(topOffset);
    }];
    
    [self.favoriteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(self.buttonWidth);
        make.left.equalTo(self.pinButton.mas_right).offset(self.buttonPadding);
        make.top.equalTo(self).offset(topOffset);
    }];
    
    [self.stackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(topOffset);
        make.right.equalTo(self).offset(-margin);
    }];
    
    if (Configuration.shared.showQuickActionButton) {
        [self.stackView addArrangedSubview:self.quickActionButton];
    }
    
    for (NSNumber *typeNumber in [self shortcutButtonTypes]) {
        EZTitlebarButtonType buttonType = typeNumber.integerValue;
        EZOpenLinkButton *button = [self buttonWithType:buttonType];
        [self.stackView addArrangedSubview:button];
    }
    [self updateShortcutButtonsToolTip];
    
    [super updateConstraints];
}

#pragma mark - Public Methods

- (void)updateShortcutButtonsToolTip {
    for (NSNumber *typeNumber in [self shortcutButtonTypes]) {
        EZTitlebarButtonType buttonType = typeNumber.integerValue;
        EZOpenLinkButton *button = [self buttonWithType:buttonType];
        button.toolTip = [self toolTipStrWithButtonType:buttonType];
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:EZOpenSettingsNotification object:nil];
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
//            MMLogInfo(@"pin mouse down, state: %ld", button.buttonState);
            mm_strongify(self);
            self.pin = !self.pin;
        }];
        
        [pinButton setMouseUpBlock:^(EZButton *_Nonnull button) {
//            MMLogInfo(@"pin mouse up, state: %ld", button.buttonState);
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
                    @"title" : @"open_app_settings",
                    @"action" : NSStringFromSelector(@selector(goToSettings))
                }
            ]
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
        NSImage *image = [NSImage ez_imageWithSymbolName:@"switch.2"];
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
        _googleButton = [self createButtonWithLink:EZGoogleWebSearchURL 
                                         imageName:@"google_icon"
                                        buttonType:EZTitlebarButtonTypeGoogle];
    }
    return _googleButton;
}

- (EZOpenLinkButton *)appleDictionaryButton {
    if (!_appleDictionaryButton) {
        _appleDictionaryButton = [self createButtonWithLink:EZAppleDictionaryAppURLScheme 
                                                  imageName:EZServiceTypeAppleDictionary
                                                 buttonType:EZTitlebarButtonTypeAppleDic];
    }
    return _appleDictionaryButton;
}

- (EZOpenLinkButton *)eudicButton {
    if (!_eudicButton) {
        _eudicButton = [self createButtonWithLink:EZEudicAppURLScheme 
                                        imageName:@"Eudic"
                                       buttonType:EZTitlebarButtonTypeEudicDic];
    }
    return _eudicButton;
}


- (BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    return window.pin;
}

- (void)setPin:(BOOL)pin {
    [(EZBaseQueryWindow *)self.window updateWindowLevel:pin];

    [self updatePinButton];
}

- (NSArray<NSNumber *> *)shortcutButtonTypes {
    NSMutableArray *shortcutButtonTypes = [NSMutableArray array];
    
    // Google
    if (Configuration.shared.showGoogleQuickLink) {
        [shortcutButtonTypes addObject:@(EZTitlebarButtonTypeGoogle)];
    }
    
    // Apple Dictionary
    if (Configuration.shared.showAppleDictionaryQuickLink) {
        [shortcutButtonTypes addObject:@(EZTitlebarButtonTypeAppleDic)];
    }
    
    // Eudic
    if (Configuration.shared.showEudicQuickLink) {
        // Fix https://github.com/tisfeng/Easydict/issues/957#issuecomment-3261505123
        // Since edudic has multiple bundle ids, we don't check if installed.
        [shortcutButtonTypes addObject:@(EZTitlebarButtonTypeEudicDic)];
    }
    
    return shortcutButtonTypes.copy;
}

#pragma mark -

- (EZOpenLinkButton *)createButtonWithLink:(NSString *)link
                                 imageName:(NSString *)imageName
                                buttonType:(EZTitlebarButtonType)buttonType
{
    EZOpenLinkButton *button = [[EZOpenLinkButton alloc] init];
    button.link = link;
    button.image = [[NSImage imageNamed:imageName] resizeToSize:self.imageSize];
    button.toolTip = [self toolTipStrWithButtonType:buttonType];
    button.contentTintColor = NSColor.clearColor;
    
    [button mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.buttonSize);
    }];
    
    return button;
}

- (EZOpenLinkButton *)buttonWithType:(EZTitlebarButtonType)buttonType {
    EZOpenLinkButton *button;
    switch (buttonType) {
        case EZTitlebarButtonTypeGoogle: {
            button = self.googleButton;
            break;
        }
        case EZTitlebarButtonTypeAppleDic: {
            button = self.appleDictionaryButton;
            break;
        }
        case EZTitlebarButtonTypeEudicDic: {
            button = self.eudicButton;
            break;
        }
        default:
            break;
    }
    
    return button;
}


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

- (EZOpenLinkButton *)favoriteButton {
    if (!_favoriteButton) {
        EZOpenLinkButton *favoriteButton = [[EZOpenLinkButton alloc] init];
        _favoriteButton = favoriteButton;
        
        favoriteButton.contentTintColor = [NSColor clearColor];
        favoriteButton.clickBlock = nil;
        
        mm_weakify(self);
        [favoriteButton setClickBlock:^(EZButton *_Nonnull button) {
            mm_strongify(self);
            [self toggleFavorite];
        }];
    }
    return _favoriteButton;
}

- (void)updateFavoriteButton {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    EZBaseQueryViewController *viewController = window.queryViewController;
    NSString *queryText = viewController.inputText;
    
    BOOL isFavorited = NO;
    if (queryText.length > 0) {
        isFavorited = [FavoritesManager.shared isFavoritedWithQueryText:queryText];
    }
    
    CGFloat imageWidth = 18;
    CGSize imageSize = CGSizeMake(imageWidth, imageWidth);
    
    NSColor *normalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *normalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];
    
    NSImage *normalImage = [NSImage ez_imageWithSymbolName:@"star"];
    NSImage *selectedImage = [NSImage ez_imageWithSymbolName:@"star.fill"];
    
    NSImage *normalLightImage = [[normalImage imageWithTintColor:normalLightTintColor] resizeToSize:imageSize];
    NSImage *normalDarkImage = [[normalImage imageWithTintColor:normalDarkTintColor] resizeToSize:imageSize];
    NSImage *selectedImageResized = [selectedImage resizeToSize:imageSize];
    
    mm_weakify(self);
    [self.favoriteButton excuteLight:^(EZHoverButton *button) {
        mm_strongify(self)
        NSImage *image = isFavorited ? selectedImageResized : normalLightImage;
        button.image = image;
    } dark:^(EZHoverButton *button) {
        mm_strongify(self)
        NSImage *image = isFavorited ? selectedImageResized : normalDarkImage;
        button.image = image;
    }];
    
    NSString *tooltip = isFavorited ? NSLocalizedString(@"remove_from_favorites", nil) : NSLocalizedString(@"add_to_favorites", nil);
    self.favoriteButton.toolTip = tooltip;
}

- (void)toggleFavorite {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    EZBaseQueryViewController *viewController = window.queryViewController;
    EZQueryModel *queryModel = viewController.queryModel;
    
    NSString *queryText = queryModel.queryText;
    if (queryText.length == 0) {
        return;
    }
    
    BOOL isFavorited = [FavoritesManager.shared isFavoritedWithQueryText:queryText];
    
    if (isFavorited) {
        // Remove from favorites
        NSArray<QueryRecord *> *favorites = [FavoritesManager.shared getAllFavorites];
        for (QueryRecord *record in favorites) {
            if ([record.queryText isEqualToString:queryText]) {
                [FavoritesManager.shared removeFavoriteWithId:record.id];
                break;
            }
        }
    } else {
        // Add to favorites
        [FavoritesManager.shared addFavoriteWithQueryText:queryText
                                             fromLanguage:queryModel.queryFromLanguage
                                               toLanguage:queryModel.queryTargetLanguage];
    }
    
    [self updateFavoriteButton];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.serviceHasUpdated object:nil];
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

@end
