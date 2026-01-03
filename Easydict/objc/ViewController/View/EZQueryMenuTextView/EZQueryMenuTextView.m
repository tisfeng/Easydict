//
//  EZQueryMenuTextView.m
//  Easydict
//
//  Created by tisfeng on 2023/10/17.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZQueryMenuTextView.h"
#import "EZWindowManager.h"
#import "EZCoordinateUtils.h"


@interface EZQueryMenuTextView ()

@property (nonatomic, copy) NSString *queryText;

@end

@implementation EZQueryMenuTextView

//- (NSMenu *)menu

- (NSMenu *)menuForEvent:(NSEvent *)event {
    // We need to rewrite menuForEvent: rather than menu, because we want custom menu itme shown in the first place.

    NSMenu *menu = [super menuForEvent:event];
    NSString *queryText = [self selectedText].ns_trim;

    if (queryText.length > 0) {
        NSString *title = [NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"query_in_app", nil), queryText];
        NSMenuItem *queryInAppMenuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(queryInApp:) keyEquivalent:@""];

        // Note that this shortcut only works when the menu is displayed.
        //    [queryInAppMenuItem setKeyEquivalentModifierMask: NSEventModifierFlagCommand];

        [queryInAppMenuItem setTarget:self];

        [menu insertItem:NSMenuItem.separatorItem atIndex:0];
        [menu insertItem:queryInAppMenuItem atIndex:0];
    }

    self.queryText = queryText;

    return menu;
}

- (void)queryInApp:(id)sender {
    EZWindowType anotherWindowType;
    EZActionType actionType = EZActionTypeInvokeQuery;

    EZWindowManager *windowManager = [EZWindowManager shared];
    EZWindowType floatingWindowType = windowManager.floatingWindowType;

    if (MyConfiguration.shared.mouseSelectTranslateWindowType == floatingWindowType) {
        anotherWindowType = MyConfiguration.shared.shortcutSelectTranslateWindowType;
    } else {
        anotherWindowType = MyConfiguration.shared.mouseSelectTranslateWindowType;
    }

    if (anotherWindowType != floatingWindowType) {
        // Note that floating window will be closed if not pinned when losing focus.
        EZBaseQueryWindow *floatingWindow = windowManager.floatingWindow;
        floatingWindow.pin = YES;

        EZBaseQueryWindow *anotherFloatingWindow = [windowManager windowWithType:anotherWindowType];
        if (anotherFloatingWindow.isPin) {
            // Focus query view controller, make sure floating window type is current query window.
            [windowManager orderFrontWindowAndFocusInputTextView:anotherFloatingWindow];
            EZBaseQueryViewController *anotherQueryViewController = anotherFloatingWindow.queryViewController;
            [anotherQueryViewController startQueryText:self.queryText actionType:actionType];
        } else {
            NSScreen *screen = EZLayoutManager.shared.screen;
            // Top left of current screen.
            CGPoint point = CGPointMake(0, screen.frame.size.height);
            CGPoint absolutePoint = [EZCoordinateUtils getTopLeftPoint:point inScreen:screen];

            [windowManager showFloatingWindowType:anotherWindowType
                                        queryText:self.queryText
                                       actionType:actionType
                                          atPoint:absolutePoint
                                completionHandler:nil];
        }
    } else {
        [windowManager.floatingWindow.queryViewController startQueryText:self.queryText actionType:actionType];
    }

    NSDictionary *parameters = @{
        @"floating_window_type" : @(floatingWindowType),
    };
    [EZAnalyticsService logEventWithName:@"query_in_app" parameters:parameters];
}

- (nullable NSString *)selectedText {
    NSArray *selectedRanges = [self selectedRanges];
    if (selectedRanges.count > 0) {
        NSRange selectedRange = [selectedRanges[0] rangeValue];
        NSString *selectedText = [[self string] substringWithRange:selectedRange];
        if (selectedRange.length == 0) {
            selectedText = [self.string wordAtIndex:selectedRange.location];
        }
        return selectedText;
    } else {
        return nil;
    }
}

@end
