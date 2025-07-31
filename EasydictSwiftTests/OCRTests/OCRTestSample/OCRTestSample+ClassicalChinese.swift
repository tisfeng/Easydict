//
//  OCRTestSampleClassicalChinese.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/29.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// Classical Chinese OCR test samples
/// Classical Chinese is a independent language, it's used in OCR text merge, so we need to test it separately.
extension OCRTestSample {
    static let classicalChineseCases: [OCRTestSample] = [
        .zhClassicalPoetry1, .zhClassicalPoetry2, .zhClassicalPoetry3,

        .zhClassicalLyrics1, .zhClassicalLyrics2, .zhClassicalLyrics3, .zhClassicalLyrics4, .zhClassicalLyrics5,
        .zhClassicalLyrics6, .zhClassicalLyrics7, .zhClassicalLyrics8, .zhClassicalLyrics9, .zhClassicalLyrics10,
        .zhClassicalLyrics11,
    ]

    static let classicalChineseExpectedResults: [OCRTestSample: String] = [
        .zhClassicalPoetry1: """
        《天涯》

        春日在天涯，天涯日又斜。
        莺啼如有泪，为湿最高花。

        一一唐 · 李商隐
        """,

        .zhClassicalPoetry2: """
        《放言五首 · 其五》

        泰山不要欺毫末，颜子无心羡老彭。
        松树千年终是朽，槿花一日自为荣。
        何须恋世常忧死，亦莫嫌身漫厌生。
        生去死来都是幻，幻人哀乐系何情。

        一唐 白居易
        """,

        .zhClassicalPoetry3: """
        《捕蝗至浮云岭山行疲茶有怀子由弟二首 · 其二》

        霜风渐欲作重阳，熠熠溪边野菊香。
        久废山行疲荦确，尚能村醉舞淋浪。
        独眠林下梦魂好，回首人间忧患长。
        杀马毁车从此逝，子来何处问行藏。

        -宋 · 苏轼
        """,

        .zhClassicalLyrics1: """
        《蝶恋花 · 又到绿杨曾折处》

        又到绿杨曾折处，不语垂鞭，踏遍清秋路。衰草连天无意绪，雁声远向萧关去。
        不恨天涯行役苦，只恨西风，吹梦成今古。明日客程还几许，沾衣况是新寒雨。

        一-清．纳兰性德
        """,

        .zhClassicalLyrics2: """
        《江城子 · 南来飞燕北归鸿》

        南来飞燕北归鸿，偶相逢，惨愁容。绿鬓朱颜重见两衰翁。别后悠悠君莫问，无限事，不言中。

        小槽春酒滴珠红，莫匆匆，满金钟。饮散落花流水各西东。后会不知何处是，烟浪远，暮云重。

        --宋 · 秦观
        """,
        .zhClassicalLyrics3: """
        《水龙吟 · 露寒烟冷蒹葭老》

        露寒烟冷蒹葭老，天外征鸿寥唳。银河秋晚，长门灯悄，一声初至。应念潇湘，岸遥人静，水多菰米。乍望极平田，徘徊欲下，依前被、风惊起。

        须信衡阳万里，有谁家、锦书遥寄。万重云外，斜行横阵，才疏又缀。仙掌月明，石头城下，影摇寒水。念征衣未捣，佳人拂杵，有盈盈泪。

        -宋 · 苏轼
        """,
        .zhClassicalLyrics4: """
        《人月圆》

        风和日蒲余烟嫩，测测透鲛绡。相逢且喜，人圆玳席，月满丹霄。
        烂游胜赏，高低灯火，鼎沸笙箫。一年三百六十日，愿长似今宵。

        --宋 · 杨无咎
        """,
        .zhClassicalLyrics5: """
        《菩萨蛮 · 书江西造口壁》

        郁孤台下清江水，中间多少行人泪。西北望长安，可怜无数山。
        青山遮不住，毕竟东流去。江晚正愁余，山深闻鹧鸪。

        --宋 · 辛弃疾
        """,
        .zhClassicalLyrics6: """
        《青玉案．天然一帧荆关画》

        天然一帧荆关画，谁打稿，斜阳下？历历水残山剩也。乱鸦干点，落鸿孤烟，中有渔樵话。
        登临我亦悲秋者，向蔓草平原泪盈把。自古有情终不化。青娥冢上，东风野火，烧出鸳鸯瓦。

        -一清 · 顾贞观
        """,
        .zhClassicalLyrics7: """
        《定风波 · 重阳》

        与客携壶上翠微，江涵秋影雁初飞，尘世难逢开口笑，年少，菊花须插满头归。
        酩酊但酬佳节了，云峤，登临不用怨斜晖。古往今来谁不老，多少，牛山何必更沾衣。

        --宋 · 苏轼
        """,
        .zhClassicalLyrics8: """
        《沁园春 · 情若连环》

        情若连环，恨如流水，甚时是休。也不须惊怪，沈郎易瘦，也不须惊怪，潘鬓先愁。总是难禁，许多魔难，奈好事教人不自由。空追想，念前欢查查，后会悠悠。

        凝眸。悔上层楼。谩惹起、新愁与旧日愁。向彩笺写遍，相思字了，重重封卷，密寄书邮。
        料到伊行，时时开看，一看一回和泪收。须知道，似这般病染，两处心头。

        --宋 · 苏轼
        """,
        .zhClassicalLyrics9: """
        鹧鸪天．元夕有所梦

        宋 · 姜夔

        肥水东流无尽期，当初不合种相思。梦中未比丹青见，暗里忽惊山鸟啼。

        春未绿，鬓先丝，人间别久不成悲。谁教岁岁红莲夜，两处沉吟各自知。
        """,
        .zhClassicalLyrics10: """
        扬州慢

        宋 · 姜夔

        淮左名都，竹西佳处，解鞍少驻初程。过春风十里，尽荠麦青青。自胡马窥江去后，废池乔木，犹厌言兵。渐黄昏、清角吹寒，都在空城。

        杜郎俊赏，算而今，重到须惊。纵豆蔻词工，青楼梦好，难赋深情。二十四桥仍在，波心荡，冷月无声。念桥边红药，年年知为谁生？
        """,
        .zhClassicalLyrics11: """
        暗香

        宋 · 姜䕫

        旧时月色，算几番照我，梅边吹笛？唤起玉人，不管清寒与攀摘。何逊而今渐老，都忘却春风词笔。但怪得竹外疏花，香冷入瑶席。

        江国，正寂寂，叹寄与路遥，夜雪初积。翠尊易泣，红萼无言耿相忆。长记曾携手处，干树压、西湖寒碧。又片片、吹尽也，几时见得？
        """,
    ]
}
