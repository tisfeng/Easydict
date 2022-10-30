//
//  RACIndexSetSequence.h
//  ReactiveObjC
//
//  Created by Sergey Gavrilyuk on 12/18/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACSequence.h"

// Private class that adapts an array to the RACSequence interface.
@interface RACIndexSetSequence : RACSequence

+ (RACSequence *)sequenceWithIndexSet:(NSIndexSet *)indexSet;

@end
