//
//  NSString+EZSplit.h
//  Easydict
//
//  Created by tisfeng on 2023/10/11.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZSplit)

/**
 Split camel case text.
 
 anchoredDraggableState --> anchored Draggable State
 AnchoredDraggableState --> Anchored Draggable State
 GetHTTP --> Get HTTP
 GetHTTPCode --> Get HTTP Code
 */
- (NSString *)splitCamelCaseText;

/**
 Split snake case text.
 
 anchored_draggable_state --> anchored draggable state
 */
- (NSString *)splitSnakeCaseText;

@end

NS_ASSUME_NONNULL_END
