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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FIRFirebaseUserAgent : NSObject

/** Returns the firebase user agent which consists of environment part and the components added via
 * `setValue:forComponent` method. */
- (NSString *)firebaseUserAgent;

/** Sets value associated with the specified component. If value is `nil` then the component is
 * removed. */
- (void)setValue:(nullable NSString *)value forComponent:(NSString *)componentName;

/** Resets manually added components. */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
