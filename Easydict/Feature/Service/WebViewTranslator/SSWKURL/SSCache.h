//
//  SSCache.h
//  SSWKURLDemo
//
//  Created by sgcy on 2021/1/20.
//  Copyright © 2021 sgcy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSCache : NSObject

+ (instancetype)sharedCache;

- (NSData *)dataForRequestId:(NSString *)requestId;
- (NSDictionary *)responseHeadersWithRequestID:(NSString *)requestId;

- (void)saveData:(NSData *)data forRequestId:(NSString *)requestId;
- (void)saveResponseHeaders:(NSDictionary *)responseHeaders forRequestId:(NSString *)requestId;
- (void)finishRequestForRequestId:(NSString *)requestId;


@end

NS_ASSUME_NONNULL_END
