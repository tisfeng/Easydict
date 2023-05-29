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


/**
 JLRRouteResponse is the response from attempting to route a JLRRouteRequest.
 */

@interface JLRRouteResponse : NSObject <NSCopying>

/// Indicates if the response is a match or not.
@property (nonatomic, assign, readonly, getter=isMatch) BOOL match;

/// The match parameters (or nil for an invalid response).
@property (nonatomic, copy, readonly, nullable) NSDictionary *parameters;

/// Check for route response equality
- (BOOL)isEqualToRouteResponse:(JLRRouteResponse *)response;


///-------------------------------
/// @name Creating Responses
///-------------------------------


/// Creates an invalid match response.
+ (instancetype)invalidMatchResponse;

/// Creates a valid match response with the given parameters.
+ (instancetype)validMatchResponseWithParameters:(NSDictionary *)parameters;

/// Unavailable, please use +invalidMatchResponse or +validMatchResponseWithParameters: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, please use +invalidMatchResponse or +validMatchResponseWithParameters: instead.
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
