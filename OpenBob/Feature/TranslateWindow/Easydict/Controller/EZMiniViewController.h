//
//  MainTabViewController.h
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZMiniViewController : NSViewController

@property (nonatomic, weak) NSWindow *window;


- (void)startQueryText:(NSString *)text;

- (void)startQueryImage:(NSImage *)image;


//- (void)resetWithState:(NSString *)stateString;
//
//- (void)resetWithState:(NSString *)stateString actionTitle:(NSString *_Nullable)actionTitle action:(void (^_Nullable)(void))action;
//
//- (void)translateText:(NSString *)text;
//
//- (void)translateImage:(NSImage *)image;
//
//- (void)retry;
//
//- (void)resetQueryViewHeightConstraint;
//
//- (void)updateFoldState:(BOOL)isFold;

@property (nonatomic, copy) void (^resizeWindowBlock)(void);

@end

NS_ASSUME_NONNULL_END
