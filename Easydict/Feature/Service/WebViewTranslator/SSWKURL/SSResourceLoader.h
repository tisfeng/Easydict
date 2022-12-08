//
//  SSResourceLoader.h
//  SSWKURLDemo
//
//  Created by sgcy on 2021/1/20.
//  Copyright © 2021 sgcy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSReourceItem : NSObject

@property (nonatomic,strong) NSURLResponse *response;
@property (nonatomic,strong) NSData *data;
@property (nonatomic,strong) NSError *error;

@end


@interface SSResourceLoader : NSObject

+ (instancetype)sharedLoader;

- (SSReourceItem *)loadResource:(NSURLRequest *)request;

- (void)preloadResourceWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
