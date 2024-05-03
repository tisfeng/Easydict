//
//  EZAboutViewController.m
//  Easydict
//
//  Created by Jerry on 2024-05-03.
//  Copyright © 2024 izual. All rights reserved.
//

#import "EZAboutViewController.h"
#import "Easydict-Swift.h"

@implementation AboutViewController

- (void)loadView {
    if (@available(macOS 13, *)) {
        // Create the SwiftUI view and use it as the NSHostingView's rootView
        AboutTabWrapper *aboutViewWrapper = [[AboutTabWrapper alloc] init];
        self.view = [aboutViewWrapper makeNSView];

    } else {
        // Fallback on earlier versions
        self.view = [[NSView alloc] init];
    }
}

@end
