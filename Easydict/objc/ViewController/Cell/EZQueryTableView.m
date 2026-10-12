//
//  EZQueryTableView.m
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

#import "EZQueryTableView.h"
#import <WebKit/WebKit.h>

/// Forwards all existing delegate decisions except table clicks inside web content.
@interface EZWebContentClickDelegate : NSObject <NSGestureRecognizerDelegate>
@property (nonatomic, strong) id<NSGestureRecognizerDelegate> originalDelegate;
@end

@implementation EZWebContentClickDelegate

- (BOOL)respondsToSelector:(SEL)selector {
    return [super respondsToSelector:selector] || [self.originalDelegate respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return self.originalDelegate;
}

- (BOOL)gestureRecognizer:(NSGestureRecognizer *)recognizer shouldAttemptToRecognizeWithEvent:(NSEvent *)event {
    NSView *contentView = event.window.contentView;
    NSView *hitView = [contentView hitTest:[contentView convertPoint:event.locationInWindow fromView:nil]];
    for (NSView *view = hitView; view; view = view.superview) {
        if ([view isKindOfClass:WKWebView.class]) {
            return NO;
        }
        if (view == recognizer.view) {
            break;
        }
    }
    if ([self.originalDelegate respondsToSelector:_cmd]) {
        return [self.originalDelegate gestureRecognizer:recognizer shouldAttemptToRecognizeWithEvent:event];
    }
    return YES;
}

@end

@interface EZQueryTableView ()
@property (nonatomic, strong) NSMapTable<NSGestureRecognizer *, EZWebContentClickDelegate *> *webClickDelegates;
@end

@implementation EZQueryTableView

- (void)addGestureRecognizer:(NSGestureRecognizer *)gestureRecognizer {
    [super addGestureRecognizer:gestureRecognizer];
    [self updateWebClickDelegates];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self updateWebClickDelegates];
}

- (void)layout {
    [super layout];
    [self updateWebClickDelegates];
}

- (void)updateWebClickDelegates {
    if (@available(macOS 27.0, *)) {
        if (!self.webClickDelegates) {
            self.webClickDelegates = [NSMapTable weakToStrongObjectsMapTable];
        }
        for (NSGestureRecognizer *recognizer in self.gestureRecognizers) {
            if (![recognizer isKindOfClass:NSClickGestureRecognizer.class] ||
                ((NSClickGestureRecognizer *)recognizer).numberOfClicksRequired != 1) {
                continue;
            }
            EZWebContentClickDelegate *existingDelegate = [self.webClickDelegates objectForKey:recognizer];
            if (existingDelegate && recognizer.delegate == existingDelegate) {
                continue;
            }
            // AppKit's table selection recognizer can consume clicks before WebKit
            // receives them. Keep its original decisions outside embedded web views.
            EZWebContentClickDelegate *delegate = [[EZWebContentClickDelegate alloc] init];
            delegate.originalDelegate = recognizer.delegate;
            [self.webClickDelegates setObject:delegate forKey:recognizer];
            recognizer.delegate = delegate;
        }
    }
}

@end
