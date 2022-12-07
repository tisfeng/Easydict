//
//  EZLinkButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/6.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLinkButton.h"
#import "EZWindowManager.h"
#import "NSObject+EZDarkMode.h"

static NSString * const EZQueryKey = @"{Query}";

@interface EZLinkButton ()

@property (nonatomic, copy) NSString *text;

@end

@implementation EZLinkButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self link_setup];
    }
    return self;
}

- (void)link_setup {
    mm_weakify(self);
    [self setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        [self openLink];
    }];
    
    self.cornerRadius = 5;
      
    // ???: Why do I need to set it up again here?  Why cannot use EZHoverButton?
    NSColor *lightHighlightColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
    NSColor *darkHighlightColor = [NSColor mm_colorWithHexString:@"#464646"];
    
    [self setMouseEnterBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        if (self.isDarkMode) {
            button.backgroundColor = darkHighlightColor;
            button.backgroundHighlightColor = darkHighlightColor;
            button.backgroundHoverColor = darkHighlightColor;
        } else {
            button.backgroundColor = lightHighlightColor;
            button.backgroundHighlightColor = lightHighlightColor;
            button.backgroundHoverColor = lightHighlightColor;
        }
    }];
    [self setMouseExitedBlock:^(EZButton *_Nonnull button) {
        button.backgroundColor = NSColor.clearColor;
    }];
}

- (void)openLink {
    EZBaseQueryViewController *viewController = (EZBaseQueryViewController *)self.window.contentViewController;
    NSString *queryText = viewController.queryText;
    [self openLinkWithText:queryText];
}

- (void)openLinkWithText:(NSString *)text {
    if (self.link.length == 0) {
        NSLog(@"open link is empty");
        return;
    }
    
    self.text = text;
    NSString *queryText = text ?: @"";
    NSString *encodedText = [queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *url = [self.link stringByReplacingOccurrencesOfString:EZQueryKey withString:@"%@"];
    
    if ([url containsString:@"%@"]) {
        url = [NSString stringWithFormat:url, encodedText];
    }
    NSLog(@"open url: %@", url);
    
    BOOL success = [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    if (success) {
        [[EZWindowManager shared] closeFloatingWindow];
    }
}

@end
