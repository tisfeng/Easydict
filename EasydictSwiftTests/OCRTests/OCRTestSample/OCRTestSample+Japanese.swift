//
//  OCRTestSampleJapanese.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/27.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// Japanese OCR test samples
extension OCRTestSample {
    // MARK: - Japanese Text Cases

    static let japaneseCases: [OCRTestSample] = [
        .jaText1, .jaText2, .jaText3, .jaText4,
    ]

    // MARK: - Japanese Expected Results

    /// Expected results for Japanese OCR test samples
    static let japaneseExpectedResults: [OCRTestSample: String] = [
        // ocr japanese text
        jaText1: """
        いつも応援して下さっているファンの皆様、
        そして関係者の皆様へ

        この度相沢みなみはAV女優として
        引退する事をご報告致します。
        急なお知らせとなり申し訳ありません。

        引退に至るまでの経緯を正直にお話しさせて頂きます。
        長くなりますが目を通して頂けると幸いです。

        私はある方にスカウトをされ約7年前に
        AV業界に入りました。
        その方は相沢みなみの生みの親でもあり、
        兄のような存在でもあり、そして私にとっては最愛の相手でもありました。
        相沢社長です。
        相沢みなみの名前は彼から頂きました。

        相沢社長には夢がありました。
        それは単体女優を育てて事務所を大きくする事。私はその夢に携われたらいいなと思い軽い気持ちでAV業界に飛び込みました。
        """,

        jaText2: """
        業界の中で盛り上がっていたアダルトオープンにてアイポケの専属女優としてデビューさせて頂きました。しかし実際は全然売れませんでした。イベントも組めないくらい。
        そして契約は切れた。早かった。悔しかった。悔しく感じたのはやる気が出ていたから。

        そのやる気を出してくれたのはファン皆様の存在です。初めて自分のファンに会えた日、
        とても嬉しかったことは今でも忘れません。そのファン達に会う為、売れなかった私達はオフ会を頻繁に開催しました。するといつからか過去の作品が売れ始め、またアイポケの専属女優として活動を再開することが出来ました。

        活動は順調でした。

        ですがデビュー3年目にして、
        その相沢社長に病気が見つかりました。
        急性白血病です。
        正直ドラマでしか知らない病気でした。
        こんな身近な人がなるなんて。言葉を失った。しかし社長は病気と戦い続けた。
        """,

        jaText3: """
        弘前ねぷたまつり開催中
        """,

        jaText4: """
        今日は世界自然保護デー
        """,
    ]
}
