//
//  EZLinkButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/6.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZOpenLinkButton.h"
#import "EZWindowManager.h"

static NSString *const EZQueryKey = @"{Query}";

@interface EZOpenLinkButton ()

@end

@implementation EZOpenLinkButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self link_setup];
    }
    return self;
}

- (void)link_setup {
    mm_weakify(self);
    [self setClickBlock:^(EZButton *_Nonnull button) {
        mm_strongify(self);
        [self openLink];
    }];

    self.cornerRadius = 5;

    // !!!: Must set different Hover color from EZHoverButton, because link button is used in titleBar, and window has the same background color as EZHoverButton.

    NSColor *lightHoverColor = [NSColor mm_colorWithHexString:@"#E6E6E6"];
    NSColor *lightHighlightColor = [NSColor mm_colorWithHexString:@"#DADADA"];

    NSColor *darkHoverColor = [NSColor mm_colorWithHexString:@"#3F3F3F"];
    NSColor *darkHighlightColor = [NSColor mm_colorWithHexString:@"#525252"];

    [self excuteLight:^(EZButton *button) {
        button.contentTintColor = [NSColor ez_imageTintLightColor];
        button.backgroundHoverColor = lightHoverColor;
        button.backgroundHighlightColor = lightHighlightColor;
    } dark:^(EZButton *button) {
        button.contentTintColor = [NSColor ez_imageTintDarkColor];
        button.backgroundHoverColor = darkHoverColor;
        button.backgroundHighlightColor = darkHighlightColor;
    }];
}

- (void)setLink:(NSString *)link {
    _link = link;
    
    self.enabled = link.length > 0;
}

- (void)openLink {
    EZBaseQueryViewController *viewController = (EZBaseQueryViewController *)self.window.contentViewController;
    NSString *queryText = viewController.inputText;
    [self openURLWithQueryText:queryText];
}

- (void)openURLWithQueryText:(NSString *)text {
    if (self.link.length == 0) {
        NSLog(@"open link is empty");
        return;
    }

    NSString *queryText = text.trim ?: @"";
    NSString *encodedText = [queryText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *urlString = [self.link stringByReplacingOccurrencesOfString:EZQueryKey withString:@"%@"];

    if ([urlString containsString:@"%@"]) {
        // https://www.google.com/search?q=hello
        urlString = [NSString stringWithFormat:urlString, encodedText];
    }
    
    // dict://美丽
    NSURL *URL = [urlString detectLink];;
    
    // If link is EZGoogleWebSearchURL and queryText is a URL, we should open URL directly.
    if ([self.link isEqualToString:EZGoogleWebSearchURL]) {
        NSURL *detectURL = [queryText detectLink];
        if (detectURL) {
            URL = detectURL;
        }
    }
    
    NSLog(@"open url: %@", URL);

    // !!!: when using openURL, URL must has scheme, like https://
    BOOL success = [[NSWorkspace sharedWorkspace] openURL:URL];
    if (success) {
        if (EZWindowManager.shared.floatingWindowType != EZWindowTypeMain) {
            [[EZWindowManager shared] closeFloatingWindow];
        }
    }
}

@end
