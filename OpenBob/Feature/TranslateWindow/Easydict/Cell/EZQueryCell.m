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
    
    mm_weakify(self);
    [queryView setUpdateQueryTextBlock:^(NSString * _Nonnull text, CGFloat textViewHeight) {
        mm_strongify(self);
                
        if (self.updateQueryTextBlock) {
            self.updateQueryTextBlock(text, textViewHeight);
        }
    }];
}

- (void)updateConstraints {
    [self.queryView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [super updateConstraints];
}

- (void)enterAction {
    if (self.enterActionBlock) {
        self.enterActionBlock(self.queryView.copiedText);
    }
}


#pragma mark - Setter

- (void)setEnterActionBlock:(void (^)(NSString * _Nonnull))enterActionBlock {
    _enterActionBlock = enterActionBlock;
    
    self.queryView.enterActionBlock = enterActionBlock;
}

- (void)setPlayAudioBlock:(void (^)(NSString * _Nonnull))audioActionBlock {
    _playAudioBlock = audioActionBlock;
    
    self.queryView.playAudioBlock = audioActionBlock;
}

- (void)setCopyTextBlock:(void (^)(NSString * _Nonnull))copyActionBlock {
    _copyTextBlock = copyActionBlock;
    
    self.queryView.copyTextBlock = copyActionBlock;
}

- (void)dealloc {
//    NSLog(@"dealloc: %@", self);
}

@end
