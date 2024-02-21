//
//  EZTableTipsCell.h
//  Easydict
//
//  Created by Sharker on 2024/2/18.
//  Copyright © 2024 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^tipsButtonClick)(NSString *url);

@interface EZTableTipsCell : NSTableRowView

@property (nonatomic, copy) tipsButtonClick moreBtnClick;

@property (nonatomic, copy) tipsButtonClick solveBtnClick;

- (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
