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
#import "JLRRouteRequest.h"
#import "JLRRouteResponse.h"

NS_ASSUME_NONNULL_BEGIN


/**
 JLRRouteDefinition is a model object representing a registered route, including the URL scheme, route pattern, and priority.
 
 This class can be subclassed to customize route parsing behavior by overriding -routeResponseForRequest:.
 -callHandlerBlockWithParameters can also be overriden to customize the parameters passed to the handlerBlock.
 */

@interface JLRRouteDefinition : NSObject <NSCopying>

/// The URL scheme for which this route applies, or JLRoutesGlobalRoutesScheme if global.
@property (nonatomic, copy, readonly) NSString *scheme;

/// The route pattern.
@property (nonatomic, copy, readonly) NSString *pattern;

/// The priority of this route pattern.
@property (nonatomic, assign, readonly) NSUInteger priority;

/// The route pattern path components.
@property (nonatomic, copy, readonly) NSArray <NSString *> *patternPathComponents;

/// The handler block to invoke when a match is found.
@property (nonatomic, copy, readonly) BOOL (^handlerBlock)(NSDictionary *parameters);

/// Check for route definition equality.
- (BOOL)isEqualToRouteDefinition:(JLRRouteDefinition *)routeDefinition;


///----------------------------------
/// @name Creating Route Definitions
///----------------------------------


/**
 Creates a new route definition. The created definition can be directly added to an instance of JLRoutes.
 
 This is the designated initializer.
 
 @param pattern The full route pattern ('/foo/:bar')
 @param priority The route priority, or 0 if default.
 @param handlerBlock The handler block to call when a successful match is found.
 
 @returns The newly initialized route definition.
 */
- (instancetype)initWithPattern:(NSString *)pattern priority:(NSUInteger)priority handlerBlock:(BOOL (^)(NSDictionary *parameters))handlerBlock NS_DESIGNATED_INITIALIZER;

/// Unavailable, use initWithScheme:pattern:priority:handlerBlock: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, use initWithScheme:pattern:priority:handlerBlock: instead.
+ (instancetype)new NS_UNAVAILABLE;


///----------------------------------
/// @name Responding To Registration
///----------------------------------


/**
 Called when the route has been registered for the given scheme.
 
 @param scheme The scheme this route has become active for.
 */
- (void)didBecomeRegisteredForScheme:(NSString *)scheme;


///-------------------------------
/// @name Matching Route Requests
///-------------------------------


/**
 Creates and returns a JLRRouteResponse for the provided JLRRouteRequest. The response specifies if there was a match or not.
 
 @param request The JLRRouteRequest to create a response for.
 
 @returns An JLRRouteResponse instance representing the result of attempting to match request to thie route definition.
 */
- (JLRRouteResponse *)routeResponseForRequest:(JLRRouteRequest *)request;


/**
 Invoke handlerBlock with the given parameters. This may be overriden by subclasses.
 
 @param parameters The parameters to pass to handlerBlock.
 
 @returns The value returned by calling handlerBlock (YES if it is considered handled and NO if not).
 */
- (BOOL)callHandlerBlockWithParameters:(NSDictionary *)parameters;


///---------------------------------
/// @name Creating Match Parameters
///---------------------------------


/**
 Creates and returns the full set of match parameters to be passed as part of a valid match.
 Subclasses can override this method to mutate the match parameters, or simply call it to generate the expected value.
 
 @param request The request being routed.
 @param routeVariables The parsed route variables (aka a route of '/route/:param' being routed with '/foo/bar' would create [ 'param' : 'bar' ])
 
 @returns The full set of match parameters to be passed as part of a valid match.
 @see defaultMatchParametersForRequest:
 @see routeVariablesForRequest:
 */
- (NSDictionary *)matchParametersForRequest:(JLRRouteRequest *)request routeVariables:(NSDictionary <NSString *, NSString *> *)routeVariables;


/**
 Creates and returns the default base match parameters for a given request. Does not include any parsed fields.
 
 @param request The request being routed.
 
 @returns The default match parameters for a given request. Only includes key/value pairs for JLRoutePatternKey, JLRouteURLKey, and JLRouteSchemeKey.
 */
- (NSDictionary *)defaultMatchParametersForRequest:(JLRRouteRequest *)request;


///-------------------------------
/// @name Parsing Route Variables
///-------------------------------


/**
 Parses and returns route variables for the given request.
 
 @param request The request to parse variable values from.
 
 @returns The parsed route variables if there was a match, or nil if it was not a match.
 */
- (nullable NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(JLRRouteRequest *)request;


/**
 Parses value into a variable name, including stripping out any extra characters if needed.
 
 @param value The raw string value that should be parsed into a variable name.
 
 @returns The variable name to use as the key of a key/value pair in the parsed route variables.
 */
- (NSString *)routeVariableNameForValue:(NSString *)value;


/**
 Parses value into a variable value, including stripping out any extra characters if needed.
 
 @param value The raw string value that should be parsed into a variable value.
 
 @returns The variable value to use as the value of a key/value pair in the parsed route variables.
 */
- (NSString *)routeVariableValueForValue:(NSString *)value;


@end


NS_ASSUME_NONNULL_END
