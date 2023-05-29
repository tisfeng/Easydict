/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol JLRRouteHandlerTarget;


/**
 JLRRouteHandler is a helper class for creating handler blocks intended to be passed to an addRoute: call.
 
 This is specifically useful for cases in which you want a separate object or class to be the handler
 for a deeplink route. An example might be a view controller class that you want to instantiate and present
 in response to a deeplink route.
 */

@interface JLRRouteHandler : NSObject

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable.
+ (instancetype)new NS_UNAVAILABLE;


/**
 Creates and returns a block that calls handleRouteWithParameters: on a weak target objet.
 
 The block returned from this method should be passed as the handler block of an addRoute: call.
 
 @param weakTarget The target object that should handle a matched route.
 
 @returns A new handler block for the provided weakTarget.
 
 @discussion There is no change of ownership of the target object, only a weak pointer (hence 'weakTarget') is captured in the block.
 If the object is deallocated, the handler will no longer be called (but the route will remain registered unless explicitly removed).
 */

+ (BOOL (^__nonnull)(NSDictionary<NSString *, id> *parameters))handlerBlockForWeakTarget:(__weak id <JLRRouteHandlerTarget>)weakTarget;


/**
 Creates and returns a block that creates a new instance of targetClass (which must conform to JLRRouteHandlerTarget), and then calls
 handleRouteWithParameters: on it. The created object is then passed as the parameter to the completion block.
 
 The block returned from this method should be passed as the handler block of an addRoute: call.
 
 @param targetClass The target class to create for handling the route request. Must conform to JLRRouteHandlerTarget.
 @param completionHandler The completion block to call after creating the new targetClass instance.
 
 @returns A new handler block for creating instances of targetClass.
 
 @discussion JLRoutes does not retain or own the created object. It's expected that the created object that is passed through the completion handler
 will be used and owned by the calling application.
 */

+ (BOOL (^__nonnull)(NSDictionary<NSString *, id> *parameters))handlerBlockForTargetClass:(Class)targetClass completion:(BOOL (^)(id <JLRRouteHandlerTarget> createdObject))completionHandler;

@end


/**
 Classes conforming to the JLRRouteHandlerTarget protocol can be used as a route handler target.
 */

@protocol JLRRouteHandlerTarget <NSObject>

@optional

/**
 Initialize an instance of the conforming class by passing matched route parameters from a JLRoutes route.
 
 @param parameters The match parameters passed to use when initializing the object. These are passed from a JLRoutes handler block.
 
 @returns An initialized instance of the conforming class.
 */

- (instancetype)initWithRouteParameters:(NSDictionary <NSString *, id> *)parameters;


/**
 Called for a successful route match.
 
 @param parameters The match parameters passed to the handler block.
 
 @returns YES if the route was handled, NO if matching a different route should be attempted.
 */

- (BOOL)handleRouteWithParameters:(NSDictionary<NSString *, id> *)parameters;

@end


NS_ASSUME_NONNULL_END
