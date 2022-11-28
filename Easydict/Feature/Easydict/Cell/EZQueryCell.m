//
//  QueryCell.m
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryCell.h"

@interface EZQueryCell ()

@end

@implementation EZQueryCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return  self;
}

- (void)setup {
    EZQueryView *queryView = [[EZQueryView alloc] initWithFrame:self.bounds];
    self.queryView = queryView;
    [self addSubview:queryView];
}

- (void)updateConstraints {
    [self.queryView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [super updateConstraints];
}

- (void)dealloc {
//    NSLog(@"dealloc: %@", self);
}

@end
