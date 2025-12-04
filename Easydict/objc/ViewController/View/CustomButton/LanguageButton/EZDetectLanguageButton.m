//
//  EZDetectLanguageButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDetectLanguageButton.h"
#import "EZLanguageManager.h"
#import "NSView+EZAnimatedHidden.h"
#import "Easydict-Swift.h"

@interface EZDetectLanguageButton ()

@property (nonatomic, strong, nullable) NSMenu *customMenu;

@property (nonatomic, strong) MMOrderedDictionary*languageDict;

@end

@implementation EZDetectLanguageButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.alphaValue = 0;
    self.title = @"";
    
    [self executeLight:^(EZButton *detectButton) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#E8E8E8"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#DCDCDC"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#CCCCCC"];
    } dark:^(EZButton *detectButton) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#3D3E3F"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#47494A"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#585A5C"];
    }];
    
    mm_weakify(self);
    [self setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        
        // 显示menu
        [self setupMenu];
        [self.customMenu popUpBelowView:self];
    }];
}

- (void)setDetectedLanguage:(EZLanguage)detectedLanguage {
    EZLanguage oldDetectedLanguage = self.detectedLanguage;
    _detectedLanguage = detectedLanguage;
    
    if (!self.showAutoLanguage && [detectedLanguage isEqualToString:EZLanguageAuto]) {
        [self setAnimatedHidden:YES];
        return;
    }
    
    [self setAnimatedHidden:NO];
    
    NSString *detectLanguageTitle = [EZLanguageManager.shared showingLanguageName:detectedLanguage];

    // Button title format: Detected English
    NSFont *titleFont = [NSFont systemFontOfSize:10];
    NSString *detectedTitle = NSLocalizedString(@"detected", nil);
    NSString *fullTitle = [NSString stringWithFormat:@"%@ %@", detectedTitle, detectLanguageTitle];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:fullTitle
                                                                                   attributes:@{
        NSFontAttributeName : titleFont,
        NSForegroundColorAttributeName : NSColor.grayColor,
    }];
    
    NSRange languageRange = NSMakeRange(detectedTitle.length + 1, detectLanguageTitle.length);
    [attrTitle addAttributes:@{
        NSForegroundColorAttributeName : [NSColor ez_blueTitleColor],
    } range:languageRange];
    self.attributedTitle = attrTitle;
    
    CGFloat width = [attrTitle mm_getTextWidth];
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width + 8);
    }];
    
    if ([self.languageDict.allKeys containsObject:detectedLanguage]) {
        [self updateLanguageMenuItem:oldDetectedLanguage state:NSControlStateValueOff];
        [self updateLanguageMenuItem:detectedLanguage state:NSControlStateValueOn];
    }
}


#pragma mark -

- (void)setupMenu {
    if (!self.customMenu) {
        self.customMenu = [NSMenu new];
    }
    [self.customMenu removeAllItems];
    
    NSArray *showingLanguages = [EZLanguageManager.shared allLanguages];
    self.languageDict = [[MMOrderedDictionary alloc] init];
    for (EZLanguage language in showingLanguages) {
        if (![language isEqualToString:EZLanguageAuto]) {
            NSString *languageNameWithFlag = [EZLanguageManager.shared showingLanguageNameWithFlag:language];
            [self.languageDict setObject:languageNameWithFlag forKey:language];
        }
    }
    
    [self.languageDict enumerateKeysAndObjectsUsingBlock:^(EZLanguage _Nonnull key, NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:obj action:@selector(clickItem:) keyEquivalent:@""];
        item.tag = idx;
        item.target = self;
        [self.customMenu addItem:item];
    }];
    
    [self updateLanguageMenuItem:self.detectedLanguage state:NSControlStateValueOn];
}

- (void)clickItem:(NSMenuItem *)item {
    EZLanguage selectedLanguage = self.languageDict.sortedKeys[item.tag];
    self.detectedLanguage = selectedLanguage;
    
    if (self.menuItemSeletedBlock) {
        self.menuItemSeletedBlock(self.detectedLanguage);
    }
    self.customMenu = nil;
}

- (void)updateLanguageMenuItem:(EZLanguage)language state:(BOOL)state {
    NSInteger index = [self.languageDict.sortedKeys indexOfObject:language];
    NSMenuItem *selectedItem = [self.customMenu itemWithTag:index];
    selectedItem.state = state;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
