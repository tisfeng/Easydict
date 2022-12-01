//
//  TablerRow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZResultCell.h"
#import "EZConst.h"

@implementation EZResultCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return  self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = EZCornerRadius_8;
    self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    EZResultView *resultView = [[EZResultView alloc] initWithFrame:self.bounds];
    [self addSubview:resultView];
    self.resultView = resultView;
}

- (void)updateConstraints {
    [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [super updateConstraints];
}

- (void)setResult:(EZQueryResult *)result {
    _result = result;
    
    [self.resultView refreshWithResult:result];
}

@end
