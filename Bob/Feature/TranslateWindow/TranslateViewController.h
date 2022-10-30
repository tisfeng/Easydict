//
//  ViewController.h
//  Bob
//
//  Created by ripper on 2019/10/19.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TranslateViewController : NSViewController

@property (nonatomic, weak) NSWindow *window;

- (void)resetWithState:(NSString *)stateString;
- (void)resetWithState:(NSString *)stateString actionTitle:(NSString * _Nullable)actionTitle action:(void (^ _Nullable )(void))action;
- (void)translateText:(NSString *)text;
- (void)translateImage:(NSImage *)image;
- (void)retry;
- (void)resetQueryViewHeightConstraint;
- (void)updateFoldState:(BOOL)isFold;

@end

NS_ASSUME_NONNULL_END
