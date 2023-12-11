//
//  AppDelegate.h
//  Easydict
//
//  Created by tisfeng on 2022/10/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/SPUStandardUpdaterController.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet SPUStandardUpdaterController *updaterController;

@end
