//
//  MMCrash.h
//  Bob
//
//  Created by ripper on 2019/12/10.
//  Copyright © 2019 ripperhe. All rights reserved.
//

///------------------------------------------------
/// Code From https://github.com/didi/DoraemonKit
///------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMCrash : NSObject

+ (void)registerHandler;

+ (NSString *)crashDirectory;

@end

NS_ASSUME_NONNULL_END
