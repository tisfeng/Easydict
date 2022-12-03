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
    }
    return self;
}

- (void)setupUI {
    self.title = @"";
    [self setupMenu];
    self.autoSelectedLanguage = EZLanguageAuto;
    
    mm_weakify(self)
    [self setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self)
        // 显示menu
        [self setupMenu];
        [self.customMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:self];
    }];
    
    [NSView mm_make:^(NSView *_Nonnull titleContainerView) {
        [self addSubview:titleContainerView];
        titleContainerView.layer.backgroundColor = [NSColor redColor].CGColor;
        titleContainerView.wantsLayer = YES;
        [titleContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.left.mas_greaterThanOrEqualTo(5);
            make.right.mas_lessThanOrEqualTo(0);
        }];
        
        self.imageView = [NSImageView mm_make:^(NSImageView *_Nonnull imageView) {
            [titleContainerView addSubview:imageView];
            NSImage *image = [NSImage imageNamed:@"arrow_down_filling"];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(titleContainerView).offset(3);
                make.centerY.equalTo(titleContainerView).offset(1);
                make.width.height.equalTo(@8);
            }];
            [imageView excuteLight:^(NSImageView *imageView) {
                imageView.image = [image imageWithTintColor:NSColor.imageTintLightColor];
            } drak:^(NSTextField *label) {
                imageView.image = [image imageWithTintColor:NSColor.imageTintDarkColor];
            }];
        }];
        
        self.textField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            [titleContainerView addSubview:textField];
            textField.stringValue = @"";
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            textField.font = [NSFont systemFontOfSize:13];
            textField.maximumNumberOfLines = 1;
            textField.lineBreakMode = NSLineBreakByTruncatingTail;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.imageView.mas_right).offset(3);
                make.top.right.bottom.equalTo(titleContainerView);
            }];
            [textField excuteLight:^(NSTextField *label) {
                label.textColor = NSColor.resultTextLightColor;
            } drak:^(NSTextField *label) {
                label.textColor = NSColor.resultTextDarkColor;
            }];
        }];
    }];
}

#pragma mark -

- (void)setupMenu {
    NSArray *allLanguages = [[EZLanguageClass allLanguages] sortedKeys];
    self.languageDict = [[MMOrderedDictionary alloc] init];
    for (EZLanguage language in allLanguages) {
        NSString *languageName = [EZLanguageManager showingLanguageName:language];
        NSString *languageFlag = [EZLanguageManager languageFlagEmoji:language];
        
        if ([language isEqualToString:EZLanguageAuto]) {
            if ([EZLanguageManager isChineseFirstLanguage] && self.autoChineseSelectedTitle.length) {
                languageName = self.autoChineseSelectedTitle;
            }
        }
        
        NSString *languageNameWithFlag = [NSString stringWithFormat:@"%@ %@", languageName, languageFlag];
        
        [self.languageDict setObject:languageNameWithFlag forKey:language];
    }
    
    if (!self.customMenu) {
        self.customMenu = [NSMenu new];
    }
    [self.customMenu removeAllItems];
    
    [self.languageDict enumerateKeysAndObjectsUsingBlock:^(EZLanguage  _Nonnull key, NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:obj action:@selector(clickItem:) keyEquivalent:@""];
        item.tag = idx;
        item.target = self;
        [self.customMenu addItem:item];
    }];
}

- (void)clickItem:(NSMenuItem *)item {
    EZLanguage selectedLanguage = self.languageDict.sortedKeys[item.tag];
    [self showSelectedLanguage:selectedLanguage];
    if (self.selectedMenuItemBlock) {
        NSLog(@"selecct: %@", selectedLanguage);
        
        self.selectedMenuItemBlock(selectedLanguage);
    }
    self.customMenu = nil;
}

- (void)showSelectedLanguage:(EZLanguage)selectedLanguage {
    if ([self.languageDict.allKeys containsObject:selectedLanguage]) {
        NSString *languageName = [EZLanguageManager showingLanguageName:selectedLanguage];
        NSString *languageFlag = [EZLanguageManager languageFlagEmoji:selectedLanguage];
        
        if ([selectedLanguage isEqualToString:EZLanguageAuto]) {
            if ([EZLanguageManager isChineseFirstLanguage] && self.autoChineseSelectedTitle.length) {
                languageName = self.autoChineseSelectedTitle;
            }
            languageFlag = [EZLanguageManager languageFlagEmoji:self.autoSelectedLanguage];
        }
        NSString *languageNameWithFlag = [NSString stringWithFormat:@"%@ %@", languageName, languageFlag];
        
        self.textField.stringValue = languageNameWithFlag;
    }
}


#pragma mark - Setter

- (void)setAutoSelectedLanguage:(EZLanguage)selectedLanguage {
    _autoSelectedLanguage = selectedLanguage;
    
    [self showSelectedLanguage:EZLanguageAuto];
}

@end
