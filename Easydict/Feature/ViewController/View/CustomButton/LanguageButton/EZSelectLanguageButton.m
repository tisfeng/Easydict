//
//  EZSelectLanguageButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/2.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZSelectLanguageButton.h"

@interface EZSelectLanguageButton ()

@property (nonatomic, strong) NSTextField *textField;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSMenu *customMenu;

@property (nonatomic, strong) MMOrderedDictionary<EZLanguage, NSString *> *languageDict;

@end

@implementation EZSelectLanguageButton

DefineMethodMMMake_m(EZSelectLanguageButton);

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        
        self.title = @"";
        [self setupMenu];
        self.autoSelectedLanguage = EZLanguageAuto;
        
        mm_weakify(self)
        [self setClickBlock:^(EZButton *_Nonnull button) {
            mm_strongify(self)
            // 显示menu
            [self setupMenu];
            [self.customMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:self];
        }];
    }
    return self;
}

- (void)setupUI {
    self.imageView = [NSImageView mm_make:^(NSImageView *_Nonnull imageView) {
        [self addSubview:imageView];
        NSImage *image = [NSImage imageNamed:@"arrow_down_filling"];
        [imageView excuteLight:^(NSImageView *imageView) {
            imageView.image = [image imageWithTintColor:[NSColor ez_imageTintLightColor]];
        } dark:^(NSImageView *imageView) {
            imageView.image = [image imageWithTintColor:[NSColor ez_imageTintDarkColor]];
        }];
    }];
    
    self.textField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
        [self addSubview:textField];
        textField.stringValue = @"";
        textField.editable = NO;
        textField.bordered = NO;
        textField.backgroundColor = NSColor.clearColor;
        textField.font = [NSFont systemFontOfSize:13];
        textField.maximumNumberOfLines = 1;
        textField.lineBreakMode = NSLineBreakByTruncatingTail;
        [textField excuteLight:^(NSTextField *label) {
            label.textColor = [NSColor ez_resultTextLightColor];
        } dark:^(NSTextField *label) {
            label.textColor = [NSColor ez_resultTextDarkColor];
        }];
    }];
}

- (void)updateConstraints {
    __block CGFloat padding = 0;
    CGFloat imageViewWidth = 8;
    [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        CGFloat leftOffset = 8;
        padding += leftOffset;
        make.left.equalTo(self).offset(leftOffset);
        make.centerY.equalTo(self).offset(1);
        make.width.height.mas_equalTo(imageViewWidth);
    }];
    
    [self.textField sizeToFit];
    CGFloat textFieldWidth = self.textField.width;
    
    [self.textField mas_updateConstraints:^(MASConstraintMaker *make) {
        CGFloat leftOffset = 3;
        padding += leftOffset;
        make.left.equalTo(self.imageView.mas_right).offset(leftOffset);
        
        CGFloat rightOffset = 3;
        padding += rightOffset;
        make.right.equalTo(self).offset(-rightOffset);
        make.centerY.equalTo(self);
        make.width.mas_equalTo(textFieldWidth);
    }];
    
    CGFloat width = padding + imageViewWidth + textFieldWidth;
    _buttonWidth = width;
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
    }];
    
    [super updateConstraints];
}

#pragma mark -

- (void)setupMenu {
    EZLanguageManager *languageManager =  [EZLanguageManager shared];
    NSArray *allLanguages = [languageManager allLanguages];
    self.languageDict = [[MMOrderedDictionary alloc] init];
    for (EZLanguage language in allLanguages) {
        NSString *languageName = [languageManager showingLanguageName:language];
        NSString *languageFlag = [languageManager languageFlagEmoji:language];
        
        if ([language isEqualToString:EZLanguageAuto]) {
            if ([languageManager isSystemChineseFirstLanguage] && self.autoChineseSelectedTitle.length) {
                languageName = self.autoChineseSelectedTitle;
            }
        }
        
        NSString *languageNameWithFlag = [NSString stringWithFormat:@"%@ %@", languageFlag, languageName];
        
        [self.languageDict setObject:languageNameWithFlag forKey:language];
    }
    
    if (!self.customMenu) {
        self.customMenu = [NSMenu new];
    }
    [self.customMenu removeAllItems];
    
    [self.languageDict enumerateKeysAndObjectsUsingBlock:^(EZLanguage _Nonnull key, NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:obj action:@selector(clickItem:) keyEquivalent:@""];
        item.tag = idx;
        item.target = self;
        [self.customMenu addItem:item];
    }];
    
    [self updateLanguageMenuItem:self.selectedLanguage state:NSControlStateValueOn];
}

- (void)clickItem:(NSMenuItem *)item {
    EZLanguage selectedLanguage = self.languageDict.sortedKeys[item.tag];
    self.selectedLanguage = selectedLanguage;
    
    if (self.selectedMenuItemBlock) {
        NSLog(@"selecct: %@", selectedLanguage);
        self.selectedMenuItemBlock(selectedLanguage);
    }
    self.customMenu = nil;
}


#pragma mark - Setter

- (void)setSelectedLanguage:(EZLanguage)selectedLanguage {
    EZLanguage oldSelectedLanguage = self.selectedLanguage;
    
    _selectedLanguage = selectedLanguage;
    
    if ([self.languageDict.allKeys containsObject:selectedLanguage]) {
        EZLanguageManager *languageManager =  [EZLanguageManager shared];

        NSString *languageName = [languageManager showingLanguageName:selectedLanguage];
        NSString *languageFlag = [languageManager languageFlagEmoji:selectedLanguage];
        
        NSString *toolTip = nil;
        
        if ([selectedLanguage isEqualToString:EZLanguageAuto]) {
            if ([languageManager isSystemChineseFirstLanguage] && self.autoChineseSelectedTitle.length) {
                languageName = self.autoChineseSelectedTitle;
            }
            languageFlag = [languageManager languageFlagEmoji:self.autoSelectedLanguage];
            
            if (![self.autoSelectedLanguage isEqualToString:EZLanguageAuto]) {
                toolTip = [languageManager showingLanguageName:self.autoSelectedLanguage];
            }
        }
        NSString *languageNameWithFlag = [NSString stringWithFormat:@"%@ %@", languageName, languageFlag];
        
        self.textField.stringValue = languageNameWithFlag;
        self.toolTip = toolTip;
        
        [self updateLanguageMenuItem:oldSelectedLanguage state:NSControlStateValueOff];
        [self updateLanguageMenuItem:selectedLanguage state:NSControlStateValueOn];
        
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)updateLanguageMenuItem:(EZLanguage)language state:(BOOL)state {
    NSInteger index = [self.languageDict.sortedKeys indexOfObject:language];
    NSMenuItem *selectedItem = [self.customMenu itemWithTag:index];
    selectedItem.state = state;
}

- (void)setAutoSelectedLanguage:(EZLanguage)selectedLanguage {
    _autoSelectedLanguage = selectedLanguage;
    
    self.selectedLanguage = EZLanguageAuto;
}

- (void)updateTextFieldLayout {
    [self.textField sizeToFit];
    CGRect frame = self.textField.frame;
    NSLog(@"self.textField: %@, %@", @(self.textField.frame), self.textField.stringValue);
    
    [self.textField mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ceil(frame.size.width));
    }];
    
    [self setNeedsUpdateConstraints:YES];
}

@end
