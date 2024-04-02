//
//  EZURLSchemeHandler.h
//  Easydict
//
//  Created by tisfeng on 2022/12/8.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZURLSchemeHandler : NSObject <WKURLSchemeHandler>

- (void)monitorBaseURLString:(NSString *)url completionHandler:(nullable void (^)(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error))completionHandler;

- (void)removeMonitorBaseURLString:(NSString *)url;
- (BOOL)containsMonitorBaseURLString:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
