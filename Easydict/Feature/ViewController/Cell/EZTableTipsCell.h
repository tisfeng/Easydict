//
//  EZTableTipsCell.h
//  Easydict
//
//  Created by Sharker on 2024/2/18.
//  Copyright © 2024 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZTableTipsCell : NSTableRowView

@property (nonatomic, copy) dispatch_block_t moreBtnClick;

@property (nonatomic, copy) dispatch_block_t solveBtnClick;

@end

NS_ASSUME_NONNULL_END
