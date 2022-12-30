//
//  EZConst.h
//  Bob
//
//  Created by tisfeng on 2022/11/11.
//  Copyright © 2022 izual. All rights reserved.
//

#ifndef EZConst_h
#define EZConst_h

static CGFloat const EZHorizontalCellSpacing_12 = 12;
static CGFloat const EZVerticalCellSpacing_8 = 8;

static CGFloat const EZCornerRadius_8 = 8;

static CGFloat const EZTitlebarHeight_28 = 28;

static CGFloat const EZAudioButtonWidth_25 = 25;
static CGFloat const EZAudioButtonImageWidth_15 = 15;

static NSString *const EZBundleId = @"com.izual.Easydict";

static NSString *const EZUserAgent = @"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36";


// ???: If value is not 0.2, it seems will block animation, because default animationResizeTime is 0.2 ?
static NSTimeInterval const EZUpdateTableViewRowHeightAnimationDuration = 0.2;

#endif /* EZConst_h */
