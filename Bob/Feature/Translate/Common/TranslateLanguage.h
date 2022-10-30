//
//  TranslateLanguage.h
//  Bob
//
//  Created by ripper on 2019/11/14.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 语言代码
 * https://zh.wikipedia.org/wiki/ISO_639-1
 * https://zh.wikipedia.org/wiki/ISO_639-2
 * https://zh.wikipedia.org/wiki/ISO_639-3
 * http://www.lingoes.cn/zh/translator/langcode.htm
 * https://www.iana.org/assignments/language-tags/language-tags.xhtml
 */


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, Language) {
    /// 自动检测/自动选择/未知
    Language_auto,
    /// 中文简体
    Language_zh_Hans,
    /// 中文繁体
    Language_zh_Hant,
    /// 中文粤语
    Language_yue,
    /// 中文文言文
    Language_wyw,
    /// 英语
    Language_en,
    /// 日语
    Language_ja,
    /// 韩语
    Language_ko,
    /// 法语
    Language_fr,
    /// 西班牙语
    Language_es,
    /// 泰语
    Language_th,
    /// 阿拉伯语
    Language_ar,
    /// 俄语
    Language_ru,
    /// 葡萄牙语
    Language_pt,
    /// 德语
    Language_de,
    /// 意大利语
    Language_it,
    /// 希腊语
    Language_el,
    /// 荷兰语
    Language_nl,
    /// 波兰语
    Language_pl,
    /// 保加利亚语
    Language_bg,
    /// 爱沙尼亚语
    Language_et,
    /// 丹麦语
    Language_da,
    /// 芬兰语
    Language_fi,
    /// 捷克语
    Language_cs,
    /// 罗马尼亚语
    Language_ro,
    /// 斯洛文尼亚语
    Language_sl,
    /// 瑞典语
    Language_sv,
    /// 匈牙利语
    Language_hu,
    /// 越南语
    Language_vi,
    /// 印尼语
    Language_id,
    /// 南非语
    Language_af,
    /// 波斯尼亚语
    Language_bs,
    /// 加泰隆语
    Language_ca,
    /// 克罗地亚语
    Language_hr,
    /// 斐济语
    Language_fj,
    /// 海地克里奥尔语
    Language_ht,
    /// 希伯来语
    Language_he,
    /// 印地语
    Language_hi,
    /// 白苗语
    Language_mww,
    /// 斯瓦希里语
    Language_sw,
    /// 克林贡语
    Language_tlh,
    /// 拉脱维亚语
    Language_lv,
    /// 立陶宛语
    Language_lt,
    /// 马来语
    Language_ms,
    /// 马耳他语
    Language_mt,
    /// 挪威语
    Language_no,
    /// 波斯语
    Language_fa,
    /// 克雷塔罗奥托米语
    Language_otq,
    /// 塞尔维亚语-西里尔文
    Language_sr_Cyrl,
    /// 塞尔维亚语-拉丁文
    Language_sr_Latn,
    /// 斯洛伐克语
    Language_sk,
    /// 塔希提语
    Language_ty,
    /// 汤加语
    Language_to,
    /// 土耳其语
    Language_tr,
    /// 乌克兰语
    Language_uk,
    /// 乌尔都语
    Language_ur,
    /// 威尔士语
    Language_cy,
    /// 尤卡坦玛雅语
    Language_yua,
    /// 阿尔巴尼亚语
    Language_sq,
    /// 阿姆哈拉语
    Language_am,
    /// 亚美尼亚语
    Language_hy,
    /// 阿塞拜疆语
    Language_az,
    /// 孟加拉语    
    Language_bn,
    /// 巴斯克语
    Language_eu,
    /// 白俄罗斯语
    Language_be,
    /// 宿务语
    Language_ceb,
    /// 科西嘉语
    Language_co,
    /// 世界语
    Language_eo,
    /// 菲律宾语
    Language_tl,
    /// 弗里西语
    Language_fy,
    /// 加利西亚语
    Language_gl,
    /// 格鲁吉亚语    
    Language_ka,
    /// 古吉拉特语
    Language_gu,
    /// 豪萨语
    Language_ha,
    /// 夏威夷语
    Language_haw,
    /// 冰岛语
    Language_is,
    /// 伊博语
    Language_ig,
    /// 爱尔兰语
    Language_ga,
    /// 爪哇语    
    Language_jw,
    /// 卡纳达语
    Language_kn,
    /// 哈萨克语
    Language_kk,
    /// 高棉语
    Language_km,
    /// 库尔德语
    Language_ku,
    /// 柯尔克孜语
    Language_ky,
    /// 老挝语
    Language_lo,
    /// 拉丁语
    Language_la,
    /// 卢森堡语
    Language_lb,
    /// 马其顿语
    Language_mk,
    /// 马尔加什语
    Language_mg,
    /// 马拉雅拉姆语
    Language_ml,
    /// 毛利语
    Language_mi,
    /// 马拉地语
    Language_mr,
    /// 蒙古语
    Language_mn,
    /// 缅甸语
    Language_my,
    /// 尼泊尔语
    Language_ne,
    /// 齐切瓦语
    Language_ny,
    /// 普什图语
    Language_ps,
    /// 旁遮普语
    Language_pa,
    /// 萨摩亚语
    Language_sm,
    /// 苏格兰盖尔语
    Language_gd,
    /// 塞索托语
    Language_st,
    /// 修纳语
    Language_sn,
    /// 信德语
    Language_sd,
    /// 僧伽罗语
    Language_si,
    /// 索马里语
    Language_so,
    /// 巽他语
    Language_su,
    /// 塔吉克语
    Language_tg,
    /// 泰米尔语
    Language_ta,
    /// 泰卢固语
    Language_te,
    /// 乌兹别克语
    Language_uz,
    /// 科萨语
    Language_xh,
    /// 意第绪语
    Language_yi,
    /// 约鲁巴语
    Language_yo,
    /// 祖鲁语
    Language_zu,
    /// 苗语
    Language_hmn,
    /// 塞尔维亚语
    Language_sr,
};

/// 根据枚举获取语言描述
NSString * _Nullable LanguageDescFromEnum(Language lang);

NS_ASSUME_NONNULL_END
