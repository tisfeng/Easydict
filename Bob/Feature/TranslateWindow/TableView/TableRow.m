//
//  TablerRow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "TableRow.h"

@implementation TableRow

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        ResultView *resultView = [[ResultView alloc] init];
        self.resultView = resultView;
        [self addSubview:resultView];
        
        [resultView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

    }
    return  self;
}

- (void)setResult:(TranslateResult *)result {
    _result = result;
    
    [self.resultView refreshWithResult:result];
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
    [[NSColor orangeColor] setFill];
    NSRectFill(dirtyRect);
}

@end
