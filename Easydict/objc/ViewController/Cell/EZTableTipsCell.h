//
//  EZTableTipsCell.h
//  Easydict
//
//  Created by Sharker on 2024/2/18.
//  Copyright © 2024 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EZTipsCellType) {
    EZTipsCellTypeNone = -1,
    EZTipsCellTypeTextEmpty = 0,
    EZTipsCellTypeMouseHover,
    EZTipsCellTypeBeep,
    EZTipsCellTypeEditButton,
    EZTipsCellTypeMightSelecting,
    EZTipsCellTypeWordSelectionOCR,
    EZTipsCellTypeSelectWords,
    EZTipsCellTypeStillPopup,
    EZTipsCellTypeErrorTips,
    EZTipsCellTypeWarnTips,
    EZTipsCellTypeInfoTips,
};

@interface EZTableTipsCell : NSTableRowView

- (CGFloat)cellHeight;


- (instancetype)initWithFrame:(CGRect)frame type:(EZTipsCellType)type;
- (instancetype)initWithFrame:(NSRect)frame
                         type:(EZTipsCellType)type
                      content:(NSString *)content;

/// update tips cell content with type
/// - Parameters:
///   - content: string value for content
///   - type: cell type default value is none
- (void)updateTipsContent:(NSString *)content type:(EZTipsCellType)type;


/// update tips cell of type
/// - Parameter type: cell type default value is none
- (void)updateTipsCellType:(EZTipsCellType)type;

@end

NS_ASSUME_NONNULL_END
