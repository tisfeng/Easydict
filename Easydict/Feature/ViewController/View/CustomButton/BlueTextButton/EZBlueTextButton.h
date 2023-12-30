//
//  EZBlueTextButton.h
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZHoverButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZBlueTextButton : EZHoverButton

@property (nonatomic, assign) CGFloat expandValue; // default is 5.

@property (nonatomic, copy, nullable) NSString *openURL;
@property (nonatomic, assign) BOOL closeWindowAfterOpeningURL;

@property (nonatomic, assign) CGFloat fontSize;

@end

NS_ASSUME_NONNULL_END
