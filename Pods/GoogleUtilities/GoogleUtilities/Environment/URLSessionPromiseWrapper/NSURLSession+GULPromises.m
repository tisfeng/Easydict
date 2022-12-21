/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleUtilities/Environment/Public/GoogleUtilities/NSURLSession+GULPromises.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULURLSessionDataResponse.h"

@implementation NSURLSession (GULPromises)

- (FBLPromise<GULURLSessionDataResponse *> *)gul_dataTaskPromiseWithRequest:
    (NSURLRequest *)URLRequest {
  return [FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
    [[self dataTaskWithRequest:URLRequest
             completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                 NSError *_Nullable error) {
               if (error) {
                 reject(error);
               } else {
                 fulfill([[GULURLSessionDataResponse alloc]
                     initWithResponse:(NSHTTPURLResponse *)response
                             HTTPBody:data]);
               }
             }] resume];
  }];
}

@end
