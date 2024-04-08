//
//  XPMCountedArgument.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/11/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import "XPMArgumentSignature.h"

/** Counted or boolean argument signature. */
@interface XPMCountedArgument : XPMArgumentSignature

+ (id)countedArgumentWithSwitches:(id)switches aliases:(id)aliases;
- (id)initWithSwitches:(id)switches aliases:(id)aliases;

@end
