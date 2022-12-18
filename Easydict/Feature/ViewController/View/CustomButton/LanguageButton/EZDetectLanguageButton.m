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

@interface EZDetectLanguageButton ()

@property (nonatomic, strong, nullable) NSMenu *customMenu;

@property (nonatomic, strong) MMOrderedDictionary<EZLanguage, NSString *> *languageDict;

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
    
    [self excuteLight:^(EZButton *detectButton) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#EAEAEA"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#E0E0E0"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#D1D1D1"];
    } drak:^(EZButton *detectButton) {
        detectButton.backgroundColor = [NSColor mm_colorWithHexString:@"#313233"];
        detectButton.backgroundHoverColor = [NSColor mm_colorWithHexString:@"#424445"];
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#535556"];
    }];
    
    mm_weakify(self);
    [self setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        
        // 显示menu
        [self setupMenu];
        [self.customMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:self];
    }];
}

- (void)setDetectedLanguage:(EZLanguage)detectedLanguage {
    EZLanguage oldDetectedLanguage = self.detectedLanguage;
    _detectedLanguage = detectedLanguage;
    
    if ([detectedLanguage isEqualToString: EZLanguageAuto]) {
        [self setAnimatedHidden:YES];
        return;
    }
    
    [self setAnimatedHidden:NO];

    NSString *detectLanguageTitle = [EZLanguageManager showingLanguageName:detectedLanguage];
    
    NSString *title = NSLocalizedString(@"detect as", nil);
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attrTitle addAttributes:@{
        NSForegroundColorAttributeName : NSColor.grayColor,
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                       range:NSMakeRange(0, attrTitle.length)];
    
    
    NSMutableAttributedString *detectAttrTitle = [[NSMutableAttributedString alloc] initWithString:detectLanguageTitle];
    [detectAttrTitle addAttributes:@{
        NSForegroundColorAttributeName : [NSColor mm_colorWithHexString:@"#007AFF"],
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                             range:NSMakeRange(0, detectAttrTitle.length)];
    
    [attrTitle appendAttributedString:detectAttrTitle];
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
    
    NSArray *showingLanguages = [EZLanguageManager allLanguages];
    self.languageDict = [[MMOrderedDictionary alloc] init];
    for (EZLanguage language in showingLanguages) {
        if (![language isEqualToString:EZLanguageAuto]) {
            NSString *languageNameWithFlag = [EZLanguageManager showingLanguageNameWithFlag:language];
            [self.languageDict setObject:languageNameWithFlag forKey:language];
        }
    }
    
    [self.languageDict enumerateKeysAndObjectsUsingBlock:^(EZLanguage  _Nonnull key, NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
