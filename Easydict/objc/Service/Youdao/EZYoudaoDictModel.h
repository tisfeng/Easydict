//
//  EZYoudaoDictModel.h
//  Easydict
//
//  Created by tisfeng on 2022/12/31.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EZBaike;
@class EZSource;
@class EZSummaryElement;
@class EZEc;
@class EZEcWord;
@class EZReturnPhrase;
@class EZReturnPhraseL;
@class EZWordTr;
@class EZTrTr;
@class EZTrL;
@class EZWfElement;
@class EZWfWf;
@class EZMeta;
@class EZSimple;
@class EZSimpleWord;
@class EZWebTrans;
@class EZWebTranslation;
@class EZTran;
@class EZTranSummary;

@class EZCe;
@class EZCeWord;
@class EZNewhh;
@class EZDataList;
@class EZSense;
@class EZSubsense;
@class EZNewhhSource;

NS_ASSUME_NONNULL_BEGIN

@interface EZBaike : NSObject
@property (nonatomic, strong) EZSource *source;
@property (nonatomic, copy)   NSArray<EZSummaryElement *> *summarys;
@end

@interface EZSource : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@end

@interface EZSummaryElement : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *summary;
@end

@interface EZEc : NSObject
@property (nonatomic, copy, nullable)   NSArray<NSString *> *examType;
@property (nonatomic, strong) EZSource *source;
@property (nonatomic, copy)   NSArray<EZEcWord *> *word;
@end

@interface EZEcWord : NSObject
@property (nonatomic, strong) EZReturnPhrase *returnPhrase;
@property (nonatomic, copy)   NSArray<EZWordTr *> *trs;
@property (nonatomic, copy)   NSString *ukphone;
@property (nonatomic, copy)   NSString *ukspeech;
@property (nonatomic, copy)   NSString *usphone;
@property (nonatomic, copy)   NSString *usspeech;
@property (nonatomic, copy)   NSArray<EZWfElement *> *wfs;
@end

@interface EZReturnPhrase : NSObject
@property (nonatomic, strong) EZReturnPhraseL *l;
@end

@interface EZReturnPhraseL : NSObject
@property (nonatomic, copy) NSString *i;
@end

@interface EZWordTr : NSObject
@property (nonatomic, copy) NSArray<EZTrTr *> *tr;
@end

@interface EZTrTr : NSObject
@property (nonatomic, strong) EZTrL *l;
@end

@interface EZTrL : NSObject
@property (nonatomic, copy, nullable) NSString *tran; // 好的，优良的；
@property (nonatomic, copy) NSArray<id> *i; // Two types:  ec: NSString, ce: EZTextWord
@property (nonatomic, copy, nullable) NSString *pos; // adv.
@end

@interface EZTextWord : NSObject
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *href;
@property (nonatomic, copy) NSString *text;

@end

@interface EZWfElement : NSObject
@property (nonatomic, strong) EZWfWf *wf;
@end

@interface EZWfWf : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@end

@interface EZMeta : NSObject
@property (nonatomic, copy) NSArray<NSString *> *dicts;
@property (nonatomic, copy) NSString *guessLanguage;
@property (nonatomic, copy) NSString *input;
@property (nonatomic, copy) NSString *isHasSimpleDict;
@property (nonatomic, copy) NSString *lang;
@property (nonatomic, copy) NSString *le;
@end

@interface EZSimple : NSObject
@property (nonatomic, copy) NSString *query;
@property (nonatomic, copy) NSArray<EZSimpleWord *> *word;
@end

@interface EZSimpleWord : NSObject
@property (nonatomic, copy) NSString *returnPhrase;
@property (nonatomic, copy) NSString *ukphone;
@property (nonatomic, copy) NSString *ukspeech;
@property (nonatomic, copy) NSString *usphone;
@property (nonatomic, copy) NSString *usspeech;
@end

@interface EZWebTrans : NSObject
@property (nonatomic, copy) NSArray<EZWebTranslation *> *webTranslation;
@end

@interface EZWebTranslation : NSObject
@property (nonatomic, nullable, copy) NSString *same;
@property (nonatomic, copy)           NSString *key;
@property (nonatomic, copy)           NSString *keySpeech;
@property (nonatomic, copy)           NSArray<EZTran *> *trans;
@end

@interface EZTran : NSObject
@property (nonatomic, nullable, strong) EZTranSummary *summary;
@property (nonatomic, nullable, strong) NSNumber *support;
@property (nonatomic, nullable, copy)   NSString *url;
@property (nonatomic, copy)             NSString *value;
@end

@interface EZTranSummary : NSObject
@property (nonatomic, copy) NSArray<NSString *> *line;
@end


// ce
@interface EZCe : NSObject
@property (nonatomic, strong) EZSource *source;
@property (nonatomic, copy)   NSArray<EZCeWord *> *word;
@end

@interface EZCeWord : NSObject
@property (nonatomic, copy)   NSString *phone;
@property (nonatomic, strong) EZReturnPhrase *returnPhrase;
@property (nonatomic, copy)   NSArray<EZWordTr *> *trs;
@end

@interface EZNewhh : NSObject
@property (nonatomic, copy)   NSArray<EZDataList *> *dataList;
@property (nonatomic, strong) EZNewhhSource *source;
@property (nonatomic, copy)   NSString *word;
@end

@interface EZDataList : NSObject
@property (nonatomic, copy) NSString *pinyin;
@property (nonatomic, copy) NSString *seealso;
@property (nonatomic, copy) NSArray<EZSense *> *sense;
@property (nonatomic, copy) NSString *word;
@end

@interface EZSense : NSObject
@property (nonatomic, copy)           NSString *cat;
@property (nonatomic, nullable, copy) NSArray<NSString *> *def;
@property (nonatomic, nullable, copy) NSArray<NSString *> *examples;
@property (nonatomic, nullable, copy) NSArray<EZSubsense *> *subsense;
@end

@interface EZSubsense : NSObject
@property (nonatomic, copy) NSString *def;
@property (nonatomic, copy) NSArray<NSString *> *examples;
@end

@interface EZNewhhSource : NSObject
@property (nonatomic, copy) NSString *name;
@end


@interface EZYoudaoDictModel : NSObject

@property (nonatomic, strong) EZBaike *baike;
@property (nonatomic, strong) EZEc *ec;
@property (nonatomic, strong) EZCe *ce;
@property (nonatomic, strong) EZNewhh *newhh; // 现代汉语规范词典

@property (nonatomic, copy)   NSString *input;
@property (nonatomic, copy)   NSString *lang;
@property (nonatomic, copy)   NSString *le;
@property (nonatomic, strong) EZMeta *meta;
@property (nonatomic, strong) EZSimple *simple;
@property (nonatomic, strong) EZWebTrans *webTrans;

@end

NS_ASSUME_NONNULL_END
