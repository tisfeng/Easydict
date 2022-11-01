//
//  BobMacro.h
//  Bob
//
//  Created by ripper on 2019/12/28.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#define NSLog(frmt, ...) MMLogVerbose(frmt, ##__VA_ARGS__)

#define DeepDarkColor [NSColor mm_colorWithHexString:@"#26292C"]
#define DarkGrayColor [NSColor mm_colorWithHexString:@"#333435"]
#define DarkBorderColor [NSColor mm_colorWithHexString:@"#464748"]

#define LightBgColor [NSColor mm_colorWithHexString:@"#F6F6F6"]
#define DarkBgColor [NSColor mm_colorWithHexString:@"#F1F1F1"]

#define LightTextColor [NSColor mm_colorWithHexString:@"#262626"]
