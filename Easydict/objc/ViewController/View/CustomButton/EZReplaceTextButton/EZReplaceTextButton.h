//
//  EZReplaceTextButton.h
//  
//
//  Created by tisfeng on 2023/10/13.
//

#import "EZHoverButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZReplaceTextButton : EZHoverButton

- (void)replaceSelectedText:(NSString *)replacementString;

@end

NS_ASSUME_NONNULL_END
