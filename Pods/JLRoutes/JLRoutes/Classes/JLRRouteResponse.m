/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRRouteResponse.h"


@interface JLRRouteResponse ()

@property (nonatomic, assign, getter=isMatch) BOOL match;
@property (nonatomic, copy) NSDictionary *parameters;

@end


@implementation JLRRouteResponse

+ (instancetype)invalidMatchResponse
{
    JLRRouteResponse *response = [[[self class] alloc] init];
    response.match = NO;
    return response;
}

+ (instancetype)validMatchResponseWithParameters:(NSDictionary *)parameters
{
    JLRRouteResponse *response = [[[self class] alloc] init];
    response.match = YES;
    response.parameters = parameters;
    return response;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> - match: %@, params: %@", NSStringFromClass([self class]), self, (self.match ? @"YES" : @"NO"), self.parameters];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToRouteResponse:(JLRRouteResponse *)object];
    } else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToRouteResponse:(JLRRouteResponse *)response
{
    if (self.isMatch != response.isMatch) {
        return NO;
    }
    
    if (!((self.parameters == nil && response.parameters == nil) || [self.parameters isEqualToDictionary:response.parameters])) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return @(self.match).hash ^ self.parameters.hash;
}

- (id)copyWithZone:(NSZone *)zone
{
    JLRRouteResponse *copy = [[[self class] alloc] init];
    copy.match = self.isMatch;
    copy.parameters = self.parameters;
    return copy;
}

@end
