// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2019, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#ifndef SwiftLogLevel_h
#define SwiftLogLevel_h

#import <CocoaLumberjack/DDLog.h>

#ifndef DD_LOG_LEVEL
// #warning 'DD_LOG_LEVEL' is not defined. Using 'DDLogLevelAll' as default. Consider defining it yourself.
#define DD_LOG_LEVEL DDLogLevelAll
#endif

static const DDLogLevel DDDefaultLogLevel = DD_LOG_LEVEL;

#endif /* SwiftLogLevel_h */
