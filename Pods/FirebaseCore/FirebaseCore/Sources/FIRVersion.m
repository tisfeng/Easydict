/*
 * Copyright 2017 Google
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

#import "FirebaseCore/Sources/Public/FirebaseCore/FIRVersion.h"

#ifndef Firebase_VERSION
#error "Firebase_VERSION is not defined: add -DFirebase_VERSION=... to the build invocation"
#endif

// The following two macros supply the incantation so that the C
// preprocessor does not try to parse the version as a floating
// point number. See
// https://www.guyrutenberg.com/2008/12/20/expanding-macros-into-string-constants-in-c/
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

NSString* FIRFirebaseVersion(void) {
  return @STR(Firebase_VERSION);
}
