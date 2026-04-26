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
    SEL sel = sel_registerName("_cornerMask");
    Class nsWindowClass = [NSWindow class];

    unsigned int totalClasses = 0;
    // Use plain C pointer — avoids Swift's AutoreleasingUnsafeMutablePointer bridging
    // which incorrectly autoreleases class objects during subscript access.
    Class *classList = objc_copyClassList(&totalClasses);
    if (!classList) return;

    for (unsigned int i = 0; i < totalClasses; i++) {
        Class cls = classList[i];
        if (cls == nsWindowClass) continue;

        BOOL isWindowSubclass = NO;
        Class ancestor = class_getSuperclass(cls);
        while (ancestor) {
            if (ancestor == nsWindowClass) { isWindowSubclass = YES; break; }
            ancestor = class_getSuperclass(ancestor);
        }
        if (!isWindowSubclass) continue;

        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(cls, &methodCount);
        if (!methods) continue;

        BOOL hasDirectOverride = NO;
        for (unsigned int j = 0; j < methodCount; j++) {
            if (method_getName(methods[j]) == sel) { hasDirectOverride = YES; break; }
        }
        free(methods);
        if (!hasDirectOverride) continue;

        Class superCls = class_getSuperclass(cls);
        Method superMethod = class_getInstanceMethod(superCls, sel);
        Method method = class_getInstanceMethod(cls, sel);
        if (!superMethod || !method) continue;

        method_setImplementation(method, method_getImplementation(superMethod));
        NSLog(@"[WindowServer patch] Patched %s._cornerMask", class_getName(cls));
    }

    free(classList);
}
