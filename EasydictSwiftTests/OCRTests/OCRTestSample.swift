//
//  OCRTestSample.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/10.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// Enum representing the OCR test samples.
/// This provides a type-safe way to access test data, including the image name and the expected OCR text result.
enum OCRTestSample: String, CaseIterable {
    case enText1 = "ocr-en-text-1.png"
    case enText2 = "ocr-en-text-2.png"
    case enTextBitcoin = "ocr-en-text-bitcoin.png"
    case enTextReddit = "ocr-en-text-reddit.png"
    case enList = "ocr-en-list.png"
    case enLetter338 = "ocr-en-letter-338.png"
    case zhText1 = "ocr-zh-text-1.png"
    case zhText2 = "ocr-zh-text-2.png"
    case zhTextBitcoin = "ocr-zh-text-bitcoin.png"
    case jaText1 = "ocr-ja-text-1.png"
    case jaText2 = "ocr-ja-text-2.png"

    // MARK: Internal

    /// The name of the image file for the test case.
    var imageName: String {
        rawValue
    }

    /// The expected text content after OCR processing.
    var expectedText: String {
        Self.expectedResults[rawValue]!
    }

    // MARK: Private

    /// A dictionary holding the raw test data.
    private static let expectedResults: [String: String] = [
        // ocr english text
        "ocr-en-text-1.png": """
        4 cars leave Haifa together and arrive in Aviv after two hours. Explain briefly how long would it take for 8 cars?

        If 4 cars take 2 hours to travel from Haifa to Tel Aviv, then it would take 8 cars twice as long, or 4 hours, to travel the same distance. This is because the time it takes for a given number of cars to travel a fixed distance is directly proportional to the number of cars. Therefore, if the number of cars is doubled, the time it takes to travel the same distance will also be doubled.
        """,

        "ocr-en-text-2.png": """
        HEY GAMERS!

        Today, Unity (the engine we use to make our games) announced that they'll soon be taking a fee from developers for every copy of the game installed over a certain threshold - regardless of how that copy was obtained.

        Guess who has a somewhat highly anticipated game coming to Xbox Game Pass in 2024? That's right, it's us and a lot of other developers.

        That means Another Crab's Treasure will be free to install for the 25 million Game Pass subscribers. If a fraction of those users download our game, Unity could take a fee that puts an enormous dent in our income and threatens the sustainability of our business.

        And that's before we even think about sales on other platforms, or pirated installs of our game, or even multiple installs by the same user!!!\n\nThis decision puts us and countless other studios in a position where we might not be able to justify using Unity for our future titles. If these changes aren't rolled back, we'll be heavily considering abandoning our wealth of Unity expertise we've accumulated over the years and starting from scratch in a new engine. Which is really something we'd rather not do.

        On behalf of the dev community, we're calling on Unity to reverse the latest in a string of shortsighted decisions that seem to prioritize shareholders over their product's actual users.

        I fucking hate it here. -Aggro Crab
        """,

        "ocr-en-text-bitcoin.png": """
        Bitcoin: A Peer-to-Peer Electronic Cash System

        Satoshi Nakamoto satoshin@gmx.com www.bitcoin.org

        Abstract. A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution. Digital signatures provide part of the solution, but the main enefits are lost if a trusted third party is still required to prevent double-spending Ve propose a solution to the double-spending problem using a peer-to-peer network The network timestamps transactions by hashing them into an ongoing chain of hash-based proof-of-work, forming a record that cannot be changed without redoing the proof-of-work. The longest chain not only serves as proof of the sequence of events witnessed, but proof that it came from the largest pool of CPU power. As long as a majority of CPU power is controlled by nodes that are not cooperating to attack the network, they'll generate the longest chain and outpace attackers. The network itself requires minimal structure. Messages are broadcast on a best effort basis, and nodes can leave and rejoin the network at will, accepting the longest proof-of-work chain as proof of what happened while they were gone.

        1. Introduction

        Commerce on the Internet has come to rely almost exclusively on financial institutions serving as trusted third parties to process electronic payments. While the system works well enough for most transactions, it still suffers from the inherent weaknesses of the trust based model. Completely non-reversible transactions are not really possible, since financial institutions cannot avoid mediating disputes. The cost of mediation increases transaction costs, limiting the minimum practical transaction size and cutting off the possibility for small casual transactions, and there is a broader cost in the loss of ability to make non-reversible payments for nonreversible services. With the possibility of reversal, the need for trust spreads. Merchants must be wary of their customers, hassling them for more information than they would otherwise need. A certain percentage of fraud is accepted as unavoidable. These costs and payment uncertainties can be avoided in person by using physical currency, but no mechanism exists to make payments over a communications channel without a trusted party. What is needed is an electronic payment system based on cryptographic proof instead of trust, allowing any two willing parties to transact directly with each other without the need for a trusted third party. Transactions that are computationally impractical to reverse would protect sellers from fraud, and routine escrow mechanisms could easily be implemented to protect buyers. In this paper, we propose a solution to the double-spending problem using a peer-to-peer distributed timestamp server to generate computational proof of the chronological order of transactions. The system is secure as long as honest nodes collectively control more CPU power than any cooperating group of attacker nodes.
        """,

        "ocr-en-text-reddit.png": """
        I'm in love with this fucking language

        Am I allowed to rant here?

        I tried this language out a few years back and was like "what the fuck is this garbage?" and didn't look at it since then (until a week ago).

        Thing is, I'm a self taught web developer. Professionally I've only really dealt with high level languages like Javascript, Ruby, PHP, etc, and on top of that, mostly using frameworks. On my spare time l've been building a game in C++ and so l've essentially forced myself to learn something more computer-sciency.

        Over the last year or so l've been really deep-diving, learning C++, learning C, learning Crystal Lang (it's a lot like Ruby syntax). l've gained a real interest in actual CS. For the last week I've been trying out Rust and...

        Holy fuck. It's taken me a bit to start seeing the light but my god is it there.

        I have to say to all of you, you're doing a tremendous job, Rust is straight up the future, I can feel it. Fuck the rest, all my homies hate the rest. I built a shitty ass version of Next.JS in a
        """,

        "ocr-en-list.png": """
        I understand all of the rules above and am capable of following them.

        The rules are as follows:

        1. I am a girl with severe depression and severe anxiety.

        2. I am the second daughter in my family, 10 years younger than my older sister and 2 years younger
        than my younger brother.

        3. My parents always say I am 3*, and if it weren't for my cuteness
        when I was young, they would have drowned me or given me
        away.
        4. I am very introverted and have few friends.
        """,

        "ocr-en-letter-338.png": """
        It is my turn to sue and be sued. I wrote in The Second Sex about whores and prostitutes, and among names of elegant whores of 1900, I gave the name of Cléo de Mérode. Last Sunday. Somebody spoke at the radio, pretending to be me. read this part of the book, and insulted Cléo de Mérode. So now I learn in newspapers and a personal letter that she sues me. And I sue the radio for having used my name. I send you a nice picture of the woman and myself. In fact, I though she was dead since long, which would have made things much easier. Toulouse has got through a desintoxication cure; she is quite different: fair, pink, soft, smiling, dressed in a long white night-gown, looking healthy and sweet. But she spoke for an hour and a half without stopping one second, which means she was not quite normal. She was interesting because she described the way she has been nursed; it seems a terrible thing. It lasted six days. The first they gave her a mild typhoidic fever — a real shock -then every day they doped her in many different ways, pushing long thick needles in her poor flesh and veins, oily things had to go to her brain and give it some grease, for the wine had eaten the grease up, they say. She had to keep a nurse night and day, because she wanted to jump through the window, she had such anguish from lack of wine. Now it seems her brain is little too greasy, that is why she speaks so much. Yours certainly is not. What a brute, not to send a short wire when I ask to you! I very often wait patiently for letters, but this time a letter was surely lost; you never made me wait for weeks, you used to be kinder than that until now. Shall I think you unkind rather than dead? Yea, now I shall, ugly muddy thing. Don't forget anyway to send next letters to the right places: Algiers, Hotel Saint Georges until i1th or 12th March, Gardhaia, Hotel Transatlantique, until 24th March. I cannot help loving you in spite of all. Enjoy yourself, when it is still time to, for within a few months. I'll give you a hard life; I'll punish you with all kinds of tricks. And if you are really too bad, I'll send to you Cléo de Mérode. Anyway, today I kiss you with my own mouth.

        Your own Simone

        p.s. I bought two glass-swords for my home. Very beautiful.

        338
        """,

        // ocr chinese text
        "ocr-zh-text-1.png": """
        ？ 今天我把超市老板cpu干烧了

        哈哈哈，特别有意思，没想到这种数学题真的在生活中遇到了

        儿子幼儿园要求用现金买东西，挑选-付钱-找钱过程，拍个视频上传
        正好路过楼下超市我寻思把这个东西做了，然后我就跟老板说，你借
        我20块钱，我带孩子买个东西模拟一下现金支付，然后钱还你

        老板岁数挺大，五十多岁吧，说行，就给我拿出20块钱，我儿子挑了
        9块钱东西，付款20，找钱11块

        然后视频录完了，我就把11块还给了老板，同时扫码支付了9元，谢
        过之后就要走，老板给我叫住了

        老板：诶，东西你别拿走啊

        我：啊？我付钱啦，扫码付的

        老板：你用我的钱买的啊，我还找你11块钱啊

        然后我就仔细给他解释了一下，他最后还是让我走了，但是他的眼神
        中还是充满了疑惑，哈哈，突然想起来那个借钱买彩电的故事了
        """,

        "ocr-zh-text-2.png": """
        盛顿公园散步，那里有一个跳蚤市场。从第五街的公共汽车上，
        我看到夜幕慢慢地降落到纽约城上。 现在是21点，我只吃了一-小块三明治，从瓦班莎起没有睡
        觉，绝对是精疲力竭了。我在房间里喝着你的威士忌，给你写 信，但我不能这么早睡觉。在我的周围是纽约，在我的后面是我 们的夏天。我还要下楼去走，还要梦想，直到没有知觉。 我并不悲哀。也许是晕过去了，离开我自己很远，很远，无 法相信你曾经离我那么近。在出发以前，我只想对你说两件事 第一，我还是希望有朝一日再见到你。我愿意，我需要见你。但 是，请你记住，我决不会求你，不是出于自尊，而是因为如果你 不愿意，我们的见面将毫无意义，因此我将等待。如果你希望见 面，就告诉我，我不会因此认为你又爱我，甚至不会认为你希望 与我同床，我们也不必一定要长时间呆在一起，只是在你愿意的 情况下在一起。记住，我将永远希望你向我提出要求。 不，我不相信我们将不再见面。我失去了爱情，这是事实， 是痛苦的。但是我没有失去你。不管怎么说，你满足了我，纳尔 逊，你给我的一切对我是多么珍贵，你也拿不回去给我的一切。 你的温情、你的友谊对我是多么宝贵，在我想到你的时候，我仍 然觉得温暖、幸福，充满了感激之情。我希望这种温情、这种友 谊永存，永远存在。至于我，坦率地说我感到羞耻的意外的真话 是，我还像下飞机投人你那令人失望的怀抱时那样爱你，是全身 心地，是以我的全部的可怜的心爱你，我不可能少一点爱，希望 这不妨碍你，亲爱的，也不要把我们的通信当做苦役，是在你想 写信的时候才写，但你的每封信都会使我幸福的。 是的，言词看来微不足道。我觉得你离我那么近，那么近， 让我走近你。让我同过去一样，让我在自己心里永远那样。

        你的西羹榔
        """,

        "ocr-zh-text-bitcoin.png": """
        比特币：一种点对点电子货币系统

        Satoshi Nakamoto satoshin@gmx.com www.bitcoin.org

        Translated into Simplified Chinese from bitcoin.org/bitcoin.pdf by@shdxiang, xiaoxiang.io Bill Zhao (billzhao430@live.com)

        摘要：一种完全的点对点电子货币应当允许在线支付从一方直接发送到另一 方，而不需要通过一个金融机构。数字签名提供了部分解决方案，但如果仍需 一个可信任的第三方来防止双重支付，那就失去了电子货币的主要优点。我们 提出一种使用点对点网络解决双重支付问题的方案。该网络通过将交易哈希进 一条持续增长的基于哈希的工作量证明链来给交易打上时间戳，形成一条除非 重做工作量证明否则不能更改的记录。最长的链不仅是被见证事件序列的证 据，而且也是它本身是由最大CPU 算力池产生的证据。只要多数的CPU算 力被不打算联合攻击网络的节点控制，这些节点就将生成最长的链并超过攻击 者。这种网络本身只需极简的架构。信息将被尽力广播，节点可以随时离开和 重新加入网络，只需接受最长的工作量证明链作为它们离开时发生事件的证 据。

        1．简介

        互联网贸易已经变得几乎完全依赖金融机构作为可信任的第三方来处理电子支付。尽管对 于大部分交易这种系统运行得足够好，但仍需忍受基于信任模型这个固有缺点。由于金融 机构不可避免的需要仲裁纠纷，完全不可撤销的交易实际是做不到的。仲裁成本增加了交 易成本，限制了最小实际交易额度从而杜绝了日常小额交易的可能性，而且由于不支持不 可撤销支付，对不可撤销服务进行支付将需要更大的成本。由于存在交易被撤销的可能 性，对于信任的需求将更广泛。商家必须警惕他们的客户，麻烦他们提供更多他本不需要 的信息。一定比例的欺诈被认为是不可避免的。虽可通过当面使用实物货币来避免这些成 本及支付的不确定性，但不存在一个无可信任方而能在通信通道上进行支付的机制。

        我们需要的是一个基于密码学原理而不是信任的电子支付系统，该系统允许任何有交 易意愿的双方能直接交易而不需要一个可信任的第三方。交易在计算上的不可撤销将保护卖家不被欺诈，用来保护买家的程序化合约机制也应该较容易实现。在这篇论文中，我们 提出一种使用点对点分布式时间戳服务器基于时间的交易序列生成计算上的证据来解决 双重支付问题的方案。只要诚实节点集体控制的 CPU 算力大于任何一个合作攻击节点群的CPU算力，这个系统就是安全的。
        """,

        // ocr japanese text
        "ocr-ja-text-1.png": """
        いつも応援して下さっているファンの皆様、 そして関係者の皆様へ

        この度相沢みなみはAV女優として 引退する事をご報告致します。 急なお知らせとなり申し訳ありません。

        引退に至るまでの経緯を正直にお話しさせて頂 きます。 長くなりますが目を通して頂けると幸いです。
        私はある方にスカウトをされ約7年前に AV業界に入りました。 その方は相沢みなみの生みの親でもあり、 兄のような存在でもあり、そして私にとっては 最愛の相手でもありました。 相沢社長です。 相沢みなみの名前は彼から頂きました。

        相沢社長には夢がありました。 それは単体女優を育てて事務所を大きくする事。 私はその夢に携われたらいいなと思い軽い気持 ちでAV業界に飛び込みました。
        """,
        "ocr-ja-text-2.png": """
        業界の中で盛り上がっていたアダルトオー プンにてアイポケの専属女優としてデビューさ せて頂きました。しかし実際は全然売れません でした。イベントも組めないくらい。 そして契約は切れた。早かった。悔しかった。 悔しく感じたのはやる気が出ていたから。

        そのやる気を出してくれたのはファン皆様の存 在です。初めて自分のファンに会えた日、 とても嬉しかったことは今でも忘れません。 そのファン達に会う為、売れなかった私達はオ フ会を頻繁に開催しました。するといつからか 過去の作品が売れ始め、またアイポケの専属女 優として活動を再開することが出来ました。

        活動は順調でした。

        ですがデビュー3年目にして、 その相沢社長に病気が見つかりました。 急性白血病です。 正直ドラマでしか知らない病気でした。 こんな身近な人がなるなんて。言葉を失った。 しかし社長は病気と戦い続けた。
        """,
    ]
}

// swiftlint:enable line_length
