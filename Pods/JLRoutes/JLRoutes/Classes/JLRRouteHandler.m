/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRRouteHandler.h"


@implementation JLRRouteHandler

+ (BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlockForWeakTarget:(__weak id <JLRRouteHandlerTarget>)weakTarget
{
    NSParameterAssert([weakTarget respondsToSelector:@selector(handleRouteWithParameters:)]);
    
    return ^BOOL(NSDictionary<NSString *, id> *parameters) {
        return [weakTarget handleRouteWithParameters:parameters];
    };
}

+ (BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlockForTargetClass:(Class)targetClass completion:(BOOL (^)(id <JLRRouteHandlerTarget> createdObject))completionHandler
{
    NSParameterAssert([targetClass conformsToProtocol:@protocol(JLRRouteHandlerTarget)]);
    NSParameterAssert([targetClass instancesRespondToSelector:@selector(initWithRouteParameters:)]);
    NSParameterAssert(completionHandler != nil); // we want to force external ownership of the newly created object by handing it back.
    
    return ^BOOL(NSDictionary<NSString *, id> *parameters) {
        id <JLRRouteHandlerTarget> createdObject = [[targetClass alloc] initWithRouteParameters:parameters];
        return completionHandler(createdObject);
    };
}

@end
