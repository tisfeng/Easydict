//
//  QueryCell.m
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "QueryCell.h"
#import "PopUpButton.h"
#import "Translate.h"
#import "GoogleTranslate.h"
#import "Configuration.h"
#import "NSColor+MyColors.h"
#import "RoundRectButton.h"

static const CGFloat kVerticalMargin = 10;

@interface QueryCell ()

@property (nonatomic, strong) PopUpButton *fromLanguageButton;
@property (nonatomic, strong) NSButton *transformButton;
@property (nonatomic, strong) PopUpButton *toLanguageButton;
@property (nonatomic, strong) Translate *translate;
@property (nonatomic, assign) BOOL isTranslating;


@end

@implementation QueryCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.translate = [[GoogleTranslate alloc] init];
        [self setup];
    }
    return  self;
}

- (void)setup {
    QueryView *queryView = [[QueryView alloc] initWithFrame:self.bounds];
    self.queryView = queryView;
    [self addSubview:queryView];
    [self.queryView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(90);
    }];
    
    NSView *barView = [[NSView alloc] init];
    [self addSubview:barView];
    barView.wantsLayer = YES;
    barView.layer.cornerRadius = 8;
    [barView excuteLight:^(NSView *barView) {
        barView.layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
        } drak:^(NSView *barView) {
            barView.layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
        }];
    
    [barView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.queryView.mas_bottom).offset(kVerticalMargin);
        make.left.right.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(30);
        make.bottom.equalTo(self);
    }];
    
    CGFloat transformButtonWidth = 20;
    self.transformButton = [RoundRectButton mm_make:^(NSButton *_Nonnull button) {
        [barView addSubview:button];
        button.bordered = NO;
        button.toolTip = @"交换语言";
        button.imageScaling = NSImageScaleProportionallyDown;
        button.bezelStyle = NSBezelStyleRegularSquare;
        [button setButtonType:NSButtonTypeMomentaryChange];
        button.image = [NSImage imageNamed:@"transform"];

        [button excuteLight:^(id _Nonnull x) {
            button.contentTintColor = NSColor.blackColor;
        } drak:^(id _Nonnull x) {
            button.contentTintColor = NSColor.whiteColor;
        }];
        
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(barView);
            make.width.height.mas_equalTo(transformButtonWidth);
        }];
        
        mm_weakify(self)
        [button setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
            mm_strongify(self)
            Language from = Configuration.shared.from;
            Configuration.shared.from = Configuration.shared.to;
            Configuration.shared.to = from;
            [self.fromLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
            [self.toLanguageButton updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
            
            [self typeEnter];
            
            return RACSignal.empty;
        }]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Note: need to convertRect!
            CGRect rect = [self convertRect:button.frame fromView:barView];
            NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                                initWithRect:rect
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                owner:self
                                                userInfo:nil];
            [self addTrackingArea:trackingArea];
        });
    }];
    
    CGFloat languageButtonWidth = 90;
    CGFloat padding = ((self.width - transformButtonWidth) / 2 - languageButtonWidth) / 2;

    self.fromLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
        [barView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(barView);
                make.height.mas_equalTo(25);
            make.left.equalTo(self).offset(padding);
        }];
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj integerValue] == Language_auto) {
                return @"自动检测";
            }
            return LanguageDescFromEnum([obj integerValue]);
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.from]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            NSInteger from = [[self.translate.languages objectAtIndex:index] integerValue];
            NSLog(@"from 选中语言 %zd %@", from, LanguageDescFromEnum(from));
            if (from != Configuration.shared.from) {
                Configuration.shared.from = from;
                [self typeEnter];
            }
        }];
    }];
    
    
    self.toLanguageButton = [PopUpButton mm_make:^(PopUpButton *_Nonnull button) {
        [barView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.fromLanguageButton);
            make.width.height.equalTo(self.fromLanguageButton);

            make.right.equalTo(self).offset(-padding);
        }];
        [button updateMenuWithTitleArray:[self.translate.languages mm_map:^id _Nullable(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj integerValue] == Language_auto) {
                return @"自动选择";
            }
            return LanguageDescFromEnum([obj integerValue]);
        }]];
        [button updateWithIndex:[self.translate indexForLanguage:Configuration.shared.to]];
        mm_weakify(self);
        [button setMenuItemSeletedBlock:^(NSInteger index, NSString *title) {
            mm_strongify(self);
            NSInteger to = [[self.translate.languages objectAtIndex:index] integerValue];
            NSLog(@"to 选中语言 %zd %@", to, LanguageDescFromEnum(to));
            if (to != Configuration.shared.to) {
                Configuration.shared.to = to;
                [self typeEnter];
            }
        }];
    }];
}

- (void)typeEnter {
    if (self.enterActionBlock) {
        self.enterActionBlock(self.queryView);
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    CGPoint point = theEvent.locationInWindow;
    point = [self convertPoint:point fromView:nil];
    
    [self excuteLight:^(id x) {
        NSColor *highlightBgColor = [NSColor mm_colorWithHexString:@"#E2E2E2"];
        [self hightlightCopyButtonBgColor:highlightBgColor point:point];
    } drak:^(id x) {
        [self hightlightCopyButtonBgColor:DarkBorderColor point:point];
    }];
}

- (void)hightlightCopyButtonBgColor:(NSColor *)color point:(CGPoint)point {
    if (CGRectContainsPoint(self.transformButton.frame, point)) {
    }
    
    [[self.transformButton cell] setBackgroundColor:color];

}

- (void)mouseExited:(NSEvent *)theEvent {
    [[self.transformButton cell] setBackgroundColor:NSColor.clearColor];
}


- (void)setEnterActionBlock:(void (^)(QueryView * _Nonnull))enterActionBlock {
    _enterActionBlock = enterActionBlock;
    
    self.queryView.enterActionBlock = enterActionBlock;
}

// tell UIKit that you are using AutoLayout
+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {

    
    [super updateConstraints];
}



//绘制选中状态的背景
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
    [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
    [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
    NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
    [selectionPath fill];
    [selectionPath stroke];
}
//绘制背景
- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
}

@end
