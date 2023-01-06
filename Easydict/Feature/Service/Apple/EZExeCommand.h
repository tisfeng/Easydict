//
//  EZAppleScript.h
//  Easydict
//
//  Created by tisfeng on 2023/1/6.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZExeCommand : NSObject

- (void)runTranslateShortcut:(NSDictionary *)parameters
           completionHandler:(void (^)(NSString *result))completionHandler;
@end

NS_ASSUME_NONNULL_END
