//
//  EZWindowPatch.m
//  Easydict
//
//  Created by asdmoment on 2026/4/26.
//  Copyright © 2026 izual. All rights reserved.
//

#import "EZWindowPatch.h"
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

void EZPatchWindowServerCornerMask(void) {
    // Register the private selector by name only. We do not call it here;
    // the patch only compares and rewrites Objective-C method entries.
    SEL sel = sel_registerName("_cornerMask");
    Class nsWindowClass = [NSWindow class];

    // Use NSWindow's IMP as a deterministic baseline. objc_copyClassList
    // returns classes in unspecified order, so taking the IMP from each
    // class's immediate superclass would let a child patched before its
    // parent inherit the parent's still-custom IMP and keep bypassing
    // AppKit's shared cache path.
    Method baselineMethod = class_getInstanceMethod(nsWindowClass, sel);
    if (!baselineMethod) return;
    IMP baselineIMP = method_getImplementation(baselineMethod);
    if (!baselineIMP) return;

    unsigned int totalClasses = 0;
    // This returns a snapshot of classes already registered in this process.
    // Classes loaded later by a framework or bundle are not included here.
    //
    // Use a plain C pointer to avoid Swift's autoreleasing pointer bridging,
    // which can incorrectly autorelease class objects during subscript access.
    Class *classList = objc_copyClassList(&totalClasses);
    if (!classList) return;

    for (unsigned int i = 0; i < totalClasses; i++) {
        Class cls = classList[i];
        if (cls == nsWindowClass) continue;

        // Walk the superclass chain manually so private AppKit, SwiftUI,
        // QuickLook, and ImageKit window subclasses are covered too.
        BOOL isWindowSubclass = NO;
        Class ancestor = class_getSuperclass(cls);
        while (ancestor) {
            if (ancestor == nsWindowClass) {
                isWindowSubclass = YES;
                break;
            }
            ancestor = class_getSuperclass(ancestor);
        }
        if (!isWindowSubclass) continue;

        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(cls, &methodCount);
        if (!methods) continue;

        // class_copyMethodList only returns methods declared on cls itself.
        // That lets us distinguish a direct override from an inherited method.
        BOOL hasDirectOverride = NO;
        for (unsigned int j = 0; j < methodCount; j++) {
            // Selectors are uniqued by the Objective-C runtime, so pointer
            // equality is the correct comparison here.
            if (method_getName(methods[j]) == sel) {
                hasDirectOverride = YES;
                break;
            }
        }
        free(methods);
        if (!hasDirectOverride) continue;

        Method method = class_getInstanceMethod(cls, sel);
        if (!method) continue;

        // Replacing the IMP changes dispatch for all instances of this class,
        // including windows created after this startup patch runs.
        method_setImplementation(method, baselineIMP);
        NSLog(@"[WindowServer patch] Patched %s._cornerMask", class_getName(cls));
    }

    free(classList);
}
