//
//  EZConst.h
//  Easydict
//
//  Created by tisfeng on 2022/11/11.
//  Copyright © 2022 izual. All rights reserved.
//

#ifndef EZConst_h
#define EZConst_h

static CGFloat const EZHorizontalCellSpacing_10 = 10;
static CGFloat const EZVerticalCellSpacing_7 = 7;

static CGFloat const EZCornerRadius_8 = 8;

static CGFloat const EZTitlebarHeight_28 = 28;

static CGFloat const EZAudioButtonWidthHeight_24 = 24;
static CGFloat const EZAudioButtonImageWidth_16 = 16;

static CGFloat const EZAudioButtonLeftMargin_6 = 6;
static CGFloat const EZAudioButtonInputViewTopPadding_4 = 4;

static CGFloat const EZAudioButtonBottomMargin_4 = 4;
static CGFloat const EZAudioButtonRightPadding_1 = 1;


static NSString *const EZBundleId = @"com.izual.Easydict";
static NSString *const EZDebugBundleId = @"com.izual.Easydict-debug";


static NSString *const EZGithubRepoEasydict = @"tisfeng/Easydict";
static NSString *const EZGithubRepoEasydictURL = @"https://github.com/tisfeng/Easydict";

static NSString *const EZUserAgent = @"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36";


// ???: If value is not 0.2, it seems will block animation, because default animationResizeTime is 0.2 ?
static NSTimeInterval const EZUpdateTableViewRowHeightAnimationDuration = 0.2;

static NSTimeInterval const EZNetWorkTimeoutInterval = 15.0;

// !!!: This floating window level shouldn't be higher than kCGModalPanelWindowLevel, otherwise it will cover system modal alert window.
static CGFloat const EZFloatingWindowLevel = kCGModalPanelWindowLevel;

static NSInteger const EZEnglishWordMaxLength = 20;

/// Show word phrases up to 3
static NSInteger const EZMaxThreeWordPhraseCount = 3;

/// Show word synonyms up to 5
static NSInteger const EZMaxFiveWordSynonymCount = 5;

static CGFloat const EZGetClipboardTextDelayTime = 0.1;


#endif /* EZConst_h */
