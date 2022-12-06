//
//  EZLinkButton.m
//  Easydict
//
//  Created by tisfeng on 2022/12/6.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZLinkButton.h"
#import "EZWindowManager.h"

static NSString * const EZQueryKey = @"{Query}";

@interface EZLinkButton ()

@property (nonatomic, copy) NSString *text;

@end

@implementation EZLinkButton

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    mm_weakify(self);
    [self setClickBlock:^(EZButton * _Nonnull button) {
        mm_strongify(self);
        [self openLink];
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
