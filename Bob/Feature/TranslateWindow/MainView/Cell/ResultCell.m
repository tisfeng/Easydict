//
//  TablerRow.m
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "ResultCell.h"

@implementation ResultCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return  self;
}

- (void)setup {
    self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    ResultView *resultView = [[ResultView alloc] initWithFrame:self.bounds];
    [self addSubview:resultView];
    self.resultView = resultView;
}

- (void)updateConstraints {
    [self.resultView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(kResultViewMiniHeight);
    }];
    
    [super updateConstraints];
}

- (void)setResult:(TranslateResult *)result {
    _result = result;
    
    [self.resultView refreshWithResult:result];
}

@end
