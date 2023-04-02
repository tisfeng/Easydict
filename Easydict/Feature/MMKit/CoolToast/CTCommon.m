//
//  CoolToast.h
//  CoolToast
//
//  Created by Socoolby on 2019/6/28.
//  Copyright � 2019 Socoolby. All rights reserved.
//


#import "CTCommon.h"

NSBundle *CTBundle(void) {
    static dispatch_once_t onceToken;
    static NSBundle *Bundle = nil;
    dispatch_once(&onceToken, ^{
        Bundle = [NSBundle bundleWithIdentifier:@"com.socoolby.CoolToast"];
        if (!Bundle) {
            // Could be a CocoaPods framework with embedded resources bundle.
            // Look up "use_frameworks!" and "resources_bundle" in CocoaPods documentation.
            Bundle = [NSBundle bundleWithIdentifier:@"org.cocoapods.CoolToast"];
            if (!Bundle) {
                Class c = NSClassFromString(@"CoolToast");
                
                if (c) {
                    Bundle = [NSBundle bundleForClass:c];
                }
            }
            
            if (Bundle) {
                Bundle = [NSBundle bundleWithPath:[Bundle pathForResource:@"CoolToast" ofType:@"bundle"]];
            }
        }
    });
    
    if (!Bundle) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Unable to find bundle with resources."
                                     userInfo:nil];
    } else {
        return Bundle;
    }
}


NSString *CTLoc(NSString *aKey) {
    return NSLocalizedStringFromTableInBundle(aKey, @"CoolToast", CTBundle(), nil);
}

@implementation CTCommon

+ (void)delayToRunWithSecond:(float)second Block:(dispatch_block_t)block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

+ (CGSize)calculateFont:(NSString *)string withFont:(NSFont *)font {
    NSDictionary *attributes = @{NSFontAttributeName : font};
    CGSize stringBoundingBox = [string sizeWithAttributes:attributes];
    return stringBoundingBox;
}

+ (int)lineCountForText:(NSString *)text font:(NSFont *)font withinWidth:(CGFloat)width {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    int lineCount = ceil(rect.size.height / [layoutManager defaultLineHeightForFont:font]);
    return lineCount;
}

@end
