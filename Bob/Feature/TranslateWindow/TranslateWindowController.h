//
//  TranslateWindowController.h
//  Bob
//
//  Created by ripper on 2019/11/17.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TranslateWindowController : NSWindowController

+ (instancetype)shared;

- (void)selectionTranslate;

- (void)snipTranslate;

- (void)inputTranslate;

- (void)rerty;

- (void)activeLastFrontmostApplication;

@end

NS_ASSUME_NONNULL_END
