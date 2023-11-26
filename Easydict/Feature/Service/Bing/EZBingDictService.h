//
//  EZBingDictService.h
//  Easydict
//
//  Created by ChoiKarl on 2023/11/26.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZBingDictService : NSObject
- (instancetype)initWithHost:(NSString *)host;
- (void)translateWithWord:(NSString *)word;
@end

NS_ASSUME_NONNULL_END
