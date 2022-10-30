//
//  SnipFocusView.h
//  Bob
//
//  Created by ripper on 2019/11/29.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SnipFocusView : NSView

DefineMethodMMMake_h(SnipFocusView, view)

@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSTextField *locationTextField;
@property (nonatomic, strong) NSTextField *sizeTextFiled;

- (CGSize)expectSize;

@end

NS_ASSUME_NONNULL_END
