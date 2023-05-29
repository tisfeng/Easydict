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


/// Options bitmask generated from JLRoutes global options methods.
typedef NS_OPTIONS(NSUInteger, JLRRouteRequestOptions) {
    /// No options specified.
    JLRRouteRequestOptionsNone = 0,
    
    /// If present, decoding plus symbols is enabled.
    JLRRouteRequestOptionDecodePlusSymbols = 1 << 0,
    
    /// If present, treating URL hosts as path components is enabled.
    JLRRouteRequestOptionTreatHostAsPathComponent = 1 << 1
};


/**
 JLRRouteRequest is a model representing a request to route a URL.
 It gets parsed into path components and query parameters, which are then used by JLRRouteDefinition to attempt a match.
 */

@interface JLRRouteRequest : NSObject

/// The URL being routed.
@property (nonatomic, copy, readonly) NSURL *URL;

/// The URL's path components.
@property (nonatomic, strong, readonly) NSArray *pathComponents;

/// The URL's query parameters.
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/// Route request options, generally configured from the framework global options.
@property (nonatomic, assign, readonly) JLRRouteRequestOptions options;

/// Additional parameters to pass through as part of the match parameters dictionary.
@property (nonatomic, copy, nullable, readonly) NSDictionary *additionalParameters;


///-------------------------------
/// @name Creating Route Requests
///-------------------------------


/**
 Creates a new route request.
 
 @param URL The URL to route.
 @param options Options bitmask specifying parsing behavior.
 @param additionalParameters Additional parameters to include in any match dictionary created against this request.
 
 @returns The newly initialized route request.
 */
- (instancetype)initWithURL:(NSURL *)URL options:(JLRRouteRequestOptions)options additionalParameters:(nullable NSDictionary *)additionalParameters NS_DESIGNATED_INITIALIZER;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
