//
//  QueryCell.h
//  Bob
//
//  Created by tisfeng on 2022/11/4.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryCell : NSTableRowView

@property (nonatomic, strong) EZQueryView *queryView;

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, copy) NSString *detectLanguage;


@property (nonatomic, copy) void (^playAudioBlock)(NSString *text);
@property (nonatomic, copy) void (^copyTextBlock)(NSString *text);

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
