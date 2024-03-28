//
//  CoolToast.h
//  CoolToast
//
//  Created by Socoolby on 2019/6/28.
//  Copyright � 2019 Socoolby. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*!
 Return Bundle where resources can be found.
 
 @discussion Throws NSInternalInconsistencyException if bundle cannot be found.
 */
//NSBundle *CTBundle(void);


/*!
 Convenient method to get localized string from the framework bundle.
 */
NSString *CTLoc(NSString *aKey);

@interface CTCommon : NSObject

+ (void)delayToRunWithSecond:(float)second Block:(dispatch_block_t)block;
+ (CGSize)calculateFont:(NSString *)string withFont:(NSFont *)font;
+ (int)lineCountForText:(NSString *)text font:(NSFont *)font withinWidth:(CGFloat)width;

@end
