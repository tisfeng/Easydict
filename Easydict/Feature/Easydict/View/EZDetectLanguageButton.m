//
//  EZDetectLanguageButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDetectLanguageButton.h"
#import "EZLanguageManager.h"

@interface EZDetectLanguageButton ()

@property (nonatomic, strong, nullable) NSMenu *customMenu;
@property (nonatomic, strong) NSArray<NSString *> *languages;

@end

@implementation EZDetectLanguageButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hidden = YES;
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
        if (self.languages.count) {
            [self setupMenu];
            [self.customMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, 0) inView:self];
        }
    }];

    NSMutableArray *languages = [NSMutableArray array];
    NSArray *allLanguages = [[EZLanguageClass allLanguages] sortedValues];
    for (EZLanguageClass *language in allLanguages) {
        NSString *languageName = [EZLanguageManager showingLanguageName:language.englishName];
        [languages addObject:languageName];
    }
    self.languages = languages;
}

- (void)setDetectedLanguage:(EZLanguage)language {
    _detectedLanguage = language;

    if (language == EZLanguageAuto) {
        self.hidden = YES;
        return;
    }

    self.hidden = NO;

    NSString *detectLanguageTitle = [EZLanguageManager showingLanguageName:language];

    NSString *title = @"识别为 ";
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
}


#pragma mark -

- (void)setupMenu {
    if (!self.customMenu) {
        self.customMenu = [NSMenu new];
    }
    [self.customMenu removeAllItems];
    [self.languages enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:obj action:@selector(clickItem:) keyEquivalent:@""];
        item.tag = idx;
        item.target = self;
        [self.customMenu addItem:item];
    }];
}

- (void)clickItem:(NSMenuItem *)item {
    [self updateWithIndex:item.tag];
    if (self.menuItemSeletedBlock) {
        self.menuItemSeletedBlock(self.detectedLanguage);
    }
    self.customMenu = nil;
}

- (void)updateMenuWithTitleArray:(NSArray<NSString *> *)titles {
    self.languages = titles;

    if (self.customMenu) {
        [self setupMenu];
    }
}

- (void)updateWithIndex:(NSInteger)index {
    if (index >= 0 && index < self.languages.count) {
        NSString *title = [self.languages objectAtIndex:index];
        NSLog(@"title: %@", title);
        
        NSArray *allLanguages = [[EZLanguageClass allLanguages] sortedKeys];
        EZLanguage langauge = allLanguages[index];
        self.detectedLanguage = langauge;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Drawing code here.
}

@end
