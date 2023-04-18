//
//  EZRightClickDetector.h
//  Easydict
//
//  Created by tisfeng on 2023/4/18.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// Ref: https://stackoverflow.com/questions/32188581/call-action-when-nsstatusbarbutton-is-right-clicked
@interface EZRightClickDetector : NSView

@property (copy) void (^onRightMouseClicked)(NSEvent *);

@end

NS_ASSUME_NONNULL_END
