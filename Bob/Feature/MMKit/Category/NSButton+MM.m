//
//  NSButton+MM.m
//  Bob
//
//  Created by ripper on 2019/11/15.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSButton+MM.h"

@implementation NSButton (MM)

- (BOOL)mm_isOn {
    return self.state == NSControlStateValueOn;
}

- (void)setMm_isOn:(BOOL)mm_isOn {
    if (mm_isOn) {
        self.state = NSControlStateValueOn;
    }else {
        self.state = NSControlStateValueOff;
    }
}

@end
