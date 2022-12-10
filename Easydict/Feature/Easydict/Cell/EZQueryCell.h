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

@end

NS_ASSUME_NONNULL_END
