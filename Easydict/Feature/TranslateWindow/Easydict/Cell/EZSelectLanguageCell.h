//
//  EZSelectLanguageCell.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZSelectLanguageCell : NSTableRowView

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
