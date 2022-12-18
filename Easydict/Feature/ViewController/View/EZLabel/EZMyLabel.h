//
//  EZMyLabel.h
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZMyLabel : NSTextField

@property (nonatomic, assign) CGFloat characterSpacing;
@property (nonatomic, assign) CGFloat lineSpacing;
@property (nonatomic, assign) CGFloat paragraphSpacing;


@end

NS_ASSUME_NONNULL_END
