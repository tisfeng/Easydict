/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRRouteRequest.h"


@interface JLRRouteRequest ()

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong) NSArray *pathComponents;
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, assign) JLRRouteRequestOptions options;
@property (nonatomic, copy) NSDictionary *additionalParameters;

@end


@implementation JLRRouteRequest

- (instancetype)initWithURL:(NSURL *)URL options:(JLRRouteRequestOptions)options additionalParameters:(nullable NSDictionary *)additionalParameters
{
    if ((self = [super init])) {
        self.URL = URL;
        self.options = options;
        self.additionalParameters = additionalParameters;
        
        BOOL treatsHostAsPathComponent = ((options & JLRRouteRequestOptionTreatHostAsPathComponent) == JLRRouteRequestOptionTreatHostAsPathComponent);
        
        NSURLComponents *components = [NSURLComponents componentsWithString:[self.URL absoluteString]];
        
        if (components.host.length > 0 && (treatsHostAsPathComponent || (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound))) {
            // convert the host to "/" so that the host is considered a path component
            NSString *host = [components.percentEncodedHost copy];
            components.host = @"/";
            components.percentEncodedPath = [host stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
        }
        
        NSString *path = [components percentEncodedPath];
        
        // handle fragment if needed
        if (components.fragment != nil) {
            BOOL fragmentContainsQueryParams = NO;
            NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
            
            if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
                fragmentComponents.query = fragmentComponents.path;
            }
            
            if (fragmentComponents.queryItems.count > 0) {
                // determine if this fragment is only valid query params and nothing else
                fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
            }
            
            if (fragmentContainsQueryParams) {
                // include fragment query params in with the standard set
                components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
            }
            
            if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
                // handle fragment by include fragment path as part of the main path
                path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
            }
        }
        
        // strip off leading slash so that we don't have an empty first path component
        if (path.length > 0 && [path characterAtIndex:0] == '/') {
            path = [path substringFromIndex:1];
        }
        
        // strip off trailing slash for the same reason
        if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
            path = [path substringToIndex:path.length - 1];
        }
        
        // split apart into path components
        self.pathComponents = [path componentsSeparatedByString:@"/"];
        
        // convert query items into a dictionary
        NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in queryItems) {
            if (item.value == nil) {
                continue;
            }
            
            if (queryParams[item.name] == nil) {
                // first time seeing a param with this name, set it
                queryParams[item.name] = item.value;
            } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
                // already an array of these items, append it
                NSArray *values = (NSArray *)(queryParams[item.name]);
                queryParams[item.name] = [values arrayByAddingObject:item.value];
            } else {
                // existing non-array value for this key, create an array
                id existingValue = queryParams[item.name];
                queryParams[item.name] = @[existingValue, item.value];
            }
        }
        
        self.queryParams = [queryParams copy];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> - URL: %@", NSStringFromClass([self class]), self, [self.URL absoluteString]];
}

@end
