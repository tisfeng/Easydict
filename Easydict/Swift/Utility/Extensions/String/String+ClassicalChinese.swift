//
//  String+ClassicalChinese.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ClassicalChineseFeatures

enum ClassicalChineseFeatures {
    /// Classical Chinese linguistic features
    static let linguistic: [String] = [
        // Basic particles (虚词)
        "之", "乎", "者", "也", "矣", "焉", "哉", "耳", "兮", "尔", "爾",
        "而", "何", "乃", "其", "且", "若", "所", "为", "為", "耶", "邪",
        "耶", "欤", "与", "歟", "夫", "盖", "亦", "万", "莫", "将", "故",

        // Common function words (连词、介词等)
        "以", "因", "于", "於", "与", "與", "则", "則", "诸", "諸", "弗",
        "夫", "斯", "非", "无", "無", "然", "虽", "雖", "故", "已", "未",
        "将", "將", "必", "皆", "蓋", "盖", "固", "惟", "唯", "尚", "迨",
        "與", "欤", "遂", "每", "若", "如", "俾", "且", "伫", "諸", "曾",
        "嘗", "適", "偶", "猶", "庶", "几", "尤", "况", "況", "竟", "致",

        // Classical pronouns (代词)
        "吾", "余", "予", "汝", "尔", "爾", "彼", "此", "其", "之", "是",
        "伊", "厥", "維", "茲", "玆", "孰", "或", "諸", "庶", "衆", "某",

        // Additional traditional variants
        "茲", "並", "皆", "或", "亦", "云", "曰", "遂", "惟", "蓋", "過",
        "矣", "豈", "嗟", "噫", "雖", "傥", "儻", "倘", "誠", "咨", "恭",
    ]

    /// Modern Chinese linguistic features
    static let modern: [String] = [
        // Common auxiliaries (助词)
        "的", "地", "得", "了", "着", "著", "过", "過", "呢", "吧", "嘛",
        "啊", "呀", "吗", "么", "麼", "嘞", "噻", "哦", "喔", "哎", "诶",

        // Common pronouns (代词)
        "我", "你", "他", "她", "它", "这", "這", "那", "哪", "谁", "誰",
        "什么", "什麼", "怎么", "怎麼", "多少", "几", "幾", "每个", "某",

        // Common verbs and adjectives (常用动词和形容词)
        "是", "有", "没", "沒", "会", "會", "能", "要", "想", "觉得", "覺得",
        "知道", "认为", "認為", "喜欢", "喜歡", "讨厌", "討厭", "应该", "應該",

        // Conjunctions and prepositions (连词和介词)
        "和", "跟", "与", "與", "在", "把", "被", "从", "從", "向", "往",
        "因为", "因為", "所以", "但是", "然后", "然後", "如果", "虽然", "雖然",

        // Adverbs (副词)
        "很", "真", "太", "就", "才", "都", "还", "還", "已", "再", "又",
        "总是", "總是", "经常", "經常", "马上", "馬上", "赶快", "趕快",

        // Multi-character words (多字词)
        "一个", "一個", "没有", "沒有", "可以", "应该", "應該", "现在", "現在",
        "怎么样", "怎麼樣", "这样", "這樣", "那样", "那樣",
    ]

    /// Poetry specific markers
    static let poetryMarkers: [String] = [
        // Natural scenery (自然景物)
        "登高", "望远", "落日", "长河", "大漠", "黄沙", "孤舟", "明月",
        "青山", "绿水", "红叶", "白雪", "春风", "夏雨", "秋月", "冬雪",
        "残阳", "晚霞", "朝露", "暮色", "长空", "流云", "飞鸟", "落花",
        "碧水", "青云", "白云", "远山", "浮云", "清风", "细雨", "芳草",
        "松柏", "梧桐", "杨柳", "竹林", "梅花", "荷塘", "芙蓉", "兰草",

        // Time and seasons (时节)
        "春日", "夏天", "秋夜", "冬晨", "晨曦", "黄昏", "日暮", "月明",
        "四季", "寒冬", "暑夏", "清秋", "芳春", "晓", "暮", "昼", "夜",
        "早春", "残冬", "初夏", "深秋", "薄暮", "黎明", "子夜", "清晨",

        // Emotions and feelings (情感)
        "思乡", "望归", "独坐", "离恨", "愁绪", "悲秋", "伤春", "惆怅",
        "感怀", "怀古", "忆昔", "叹息", "孤独", "寂寞", "悠悠", "萧瑟",
        "缱绻", "凄清", "怅然", "感慨", "沧桑", "凄凉", "惘然", "寥落",
    ]

    /// Ci specific markers
    static let ciMarkers: [String] = [
        // Emotions and relationships (情感与人事)
        "年华", "天涯", "人家", "愁绪", "相思", "离别", "情怀", "凄凉",
        "多情", "无情", "红颜", "佳期", "良宵", "欢会", "别离", "相逢",
        "倾城", "思念", "憔悴", "销魂", "黯然", "惆怅", "寂寞", "孤独",

        // Scenery and settings (景物与场景)
        "潮平", "路带沙", "啼鸟", "晚霞", "荷花", "沽酒", "流水", "归去",
        "长亭", "短亭", "杨柳", "芳草", "回廊", "画舫", "绣户", "朱门",
        "绿窗", "雕栏", "庭院", "楼台", "亭阁", "帘幕", "月色", "花影",

        // Time and seasons (时令)
        "春光", "秋思", "暮雨", "晓风", "寒夜", "黄昏", "落日", "斜阳",
        "残月", "新月", "暮色", "晚照", "春寒", "秋凉", "夏日", "冬霜",
    ]

    /// Common Ci endings
    static let ciEndings: [String] = [
        // Common ending phrases in Ci
        "年华", "天涯", "人家", "归去", "归来", "何处", "何方", "相思", "情怀",
        "无踪", "无凭", "奈何", "如何", "怎生", "几时", "几许", "多少", "尽头",
        "归处", "归路", "归程", "归心", "归期", "归去", "归来", "归隐",
    ]

    /// Rhyming character groups
    static let rhymingGroups: [[Character]] = [
        // 东韵
        [
            "东", "同", "中", "空", "风", "松", "通", "雄", "终", "宫", "工", "童", "功", "穷", "封", "丰", "隆",
            "胸", "融", "冲", "重", "从", "龙", "蒙", "踪", "峰", "缝", "逢", "供", "恭", "聪", "茸",
        ],

        // 江韵
        [
            "江", "阳", "方", "长", "常", "房", "香", "乡", "凉", "堂", "光", "黄", "章", "扬", "良", "强", "乡",
            "芳", "翔", "粮", "妆", "装", "量", "伤", "裳", "藏", "王", "祥", "忘", "床", "梁", "肪", "香",
        ],

        // 支韵
        [
            "支", "时", "悲", "诗", "思", "之", "慈", "迟", "疑", "辞", "知", "池", "期", "规", "师", "儿", "词",
            "丝", "姿", "巴", "离", "披", "衣", "疲", "奇", "宜", "而", "肌", "脂", "眉", "卮", "碑", "题",
        ],

        // 寒韵
        ["寒", "山", "间", "闲", "颜", "斑", "还", "班", "难", "观", "残", "单", "安", "丹", "肝", "乾", "欢"],
        // 侯韵
        ["侯", "楼", "收", "求", "流", "忧", "愁", "眸", "头", "舟", "秋", "休", "州", "留", "浮", "游", "筹"],
        // 萧韵
        ["萧", "条", "遥", "潮", "桥", "娇", "饶", "销", "朝", "飘", "迢", "骄", "招", "摇", "谣", "瓢", "逍"],
        // 尤韵
        ["尤", "愁", "休", "秋", "流", "舟", "游", "头", "楼", "州", "浮", "留", "求", "酬", "俦", "筹", "稠"],
        // 齐韵
        ["齐", "低", "西", "栖", "溪", "啼", "迷", "梯", "题", "鸡", "黎", "泥", "闺", "携", "谿", "兮", "犀"],
    ]

    /// Common line separators in classical Chinese texts
    static let lineSeparators = ["。", "，", "？", "！", "；", "、"]
}

// MARK: - Classical Chinese Detection

@objc
extension NSString {
    /// Detect if the text is classical Chinese
    public func isClassicalChinese() -> Bool {
        (self as String).isClassicalChinese()
    }
}

extension String {
    // MARK: - Public Methods

    /// Detect if the text is classical Chinese
    public func isClassicalChinese() -> Bool {
        print("\n=========== Classical Chinese Detection ===========")
        print("Text: \(self)")

        if hasHighModernLinguisticFeatureRatio() {
            print("Contains too many modern features, not classical Chinese")
            return false
        }

        if isClassicalPoetry() {
            print("✅ Detected as Classical Poetry")
            return true
        }

        if isClassicalCi() {
            print("✅ Detected as Classical Ci")
            return true
        }

        let isClassical = hasHighClassicalLinguisticFeatureRatio()
        print(isClassical ? "✅ Detected as Classical Chinese prose" : "❌ Not Classical Chinese")
        return isClassical
    }

    /// Detect if the text is Chinese classical poetry (格律诗)
    public func isClassicalPoetry() -> Bool {
        print("\n----- Classical Poetry Detection -----")
        let cleanText = trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count >= 8 else { return false }

        // Split text into lines
        let lines = splitIntoLines(separatedBy: ClassicalChineseFeatures.lineSeparators)

        // Common poetry line endings
        let lineEndings = ["。", "，", "？", "！", "；"]

        // Poetry characteristics check
        guard lines.count >= 2 else { return false }

        // Check line length patterns (5/7 characters per line is common in classical poetry)
        var standardLineCount = 0
        let lineCount = lines.count

        for line in lines {
            let chars = line.filter { !lineEndings.contains(String($0)) }
            let charCount = chars.count

            if charCount == 5 || charCount == 7 {
                standardLineCount += 1
            }
        }

        // Calculate the ratio of standard-length lines
        let standardLineRatio = Double(standardLineCount) / Double(lineCount)
        print("Standard line ratio (5/7 characters): \(String(format: "%.2f", standardLineRatio))")

        // Additional poetry characteristics
        var parallelStructureCount = 0
        if lines.count >= 2 {
            // Check adjacent lines for parallel structure
            for i in 0 ..< (lines.count - 1) {
                let currentLine = lines[i]
                let nextLine = lines[i + 1]
                // Check for parallel structure (exact same length)
                if currentLine.count == nextLine.count {
                    parallelStructureCount += 1
                }
            }
        }

        // Calculate parallel structure ratio
        let parallelRatio = Double(parallelStructureCount) / Double(max(1, lineCount - 1))
        print("Parallel structure ratio: \(String(format: "%.2f", parallelRatio))")

        // Decision making logic for classical poetry:
        // 1. Most lines should be 5 or 7 characters (allowing some flexibility)
        // 2. Should have parallel structure
        let hasStandardLineLength = standardLineRatio > 0.7
        let hasParallelStructure = parallelRatio > 0.5

        // Additional check for poetry specific markers
        let hasPoetryMarkers = hasClassicalPoetrySpecificMarkers()

        print("Standard line length: \(hasStandardLineLength ? "✅" : "❌")")
        print("Parallel structure: \(hasParallelStructure ? "✅" : "❌")")
        print("Poetry markers: \(hasPoetryMarkers ? "✅" : "❌")")

        let isPoetry =
            (hasStandardLineLength && hasParallelStructure)
                || (standardLineRatio > 0.6 && hasPoetryMarkers)

        print("Poetry detection result: \(isPoetry ? "✅" : "❌")")
        return isPoetry
    }

    /// Detect if the text is Chinese classical Ci (词)
    public func isClassicalCi() -> Bool {
        print("\n----- Classical Ci Detection -----")
        let cleanText = trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count < 12 else { return false }

        // Split text into lines
        let lines = splitIntoLines(separatedBy: ClassicalChineseFeatures.lineSeparators)

        // Length check
        if cleanText.count < 12 {
            print("Text too short for Ci: \(cleanText.count) chars")
            return false
        }

        print("Number of lines: \(lines.count)")
        print("Lines: \(lines)")

        if lines.count < 2 {
            print("Too few lines for Ci")
            return false
        }

        // Check for Ci rhythmic patterns first
        if hasCiRhythmicPatterns(lines) {
            print("✅ Matched Ci rhythmic patterns")
            return true
        } else {
            print("❌ No direct Ci rhythmic patterns found, continuing with detailed analysis...")
        }

        // Ci characteristics check
        var variableLengthCount = 0
        var ciLineCount = 0
        let lineCount = lines.count

        // Lines in Ci have variable lengths between 3-11 characters typically
        for line in lines {
            let charCount = line.count

            // Count lines with typical Ci lengths
            if charCount >= 3, charCount <= 11 {
                ciLineCount += 1
            }
        }

        // Check for line length variation pattern
        if lines.count >= 3 {
            for i in 0 ..< (lines.count - 2) {
                let len1 = lines[i].count
                let len2 = lines[i + 1].count
                let len3 = lines[i + 2].count
                // Typical pattern in Ci: alternating line lengths
                if (len1 != len2) || (len2 != len3) {
                    variableLengthCount += 1
                }
            }
        }

        // Check for rhyming patterns (important in Ci)
        var rhymingCount = 0
        if lines.count >= 2 {
            for i in 0 ..< (lines.count - 1) where hasRhymingPattern(lines[i], lines[i + 1]) {
                rhymingCount += 1
            }
        }

        // Calculate and print all ratios
        let ciLineRatio = Double(ciLineCount) / Double(lineCount)
        let variableRatio = Double(variableLengthCount) / Double(max(1, lineCount - 2))
        let rhymingRatio = Double(rhymingCount) / Double(max(1, lineCount - 1))

        print("\nDetailed Ci Analysis:")
        print("- Lines with typical Ci length (3-11 chars): \(ciLineCount)/\(lineCount)")
        print("- Ci line ratio: \(String(format: "%.2f", ciLineRatio))")
        print("- Variable length patterns: \(variableLengthCount)")
        print("- Variable length ratio: \(String(format: "%.2f", variableRatio))")
        print("- Rhyming line pairs: \(rhymingCount)")
        print("- Rhyming ratio: \(String(format: "%.2f", rhymingRatio))")

        let hasCiMarkers = hasClassicalCiSpecificMarkers()
        print("\nCi Feature Check:")
        print("- Standard Ci line ratio (>0.8): \(ciLineRatio > 0.8 ? "✅" : "❌")")
        print("- Variable length ratio (>0.3): \(variableRatio > 0.3 ? "✅" : "❌")")
        print("- Rhyming ratio (>0.3): \(rhymingRatio > 0.3 ? "✅" : "❌")")
        print("- Contains Ci markers: \(hasCiMarkers ? "✅" : "❌")")

        // Check for three different patterns of Ci
        let hasStrongVariablePattern = ciLineRatio > 0.8 && variableRatio > 0.3
        let hasRhymingPattern = ciLineRatio > 0.7 && rhymingRatio > 0.3
        let hasMarkerPattern = ciLineRatio > 0.6 && hasCiMarkers

        let isCi = hasStrongVariablePattern || hasRhymingPattern || hasMarkerPattern

        print("\nFinal Ci detection result: \(isCi ? "✅ Matched" : "❌ Not matched")")
        if isCi {
            let matchedPattern =
                if hasStrongVariablePattern {
                    "Variable length pattern"
                } else if hasRhymingPattern {
                    "Rhyming pattern"
                } else {
                    "Ci markers"
                }
            print("Matched rule: \(matchedPattern)")
        }

        return isCi
    }

    // MARK: - Private Helper Methods

    private func splitIntoLines(separatedBy separators: [String]) -> [String] {
        let cleanText = trimmingCharacters(in: .whitespacesAndNewlines)
        var lines = [cleanText]

        // Split text by each separator
        for separator in separators {
            lines = lines.flatMap { $0.components(separatedBy: separator) }
        }

        return lines.filter { !$0.isEmpty }
    }

    private func hasRhymingPattern(_ line1: String, _ line2: String) -> Bool {
        guard let lastChar1 = line1.last, let lastChar2 = line2.last else {
            return false
        }

        // Check if both characters belong to the same rhyming group
        for group in ClassicalChineseFeatures.rhymingGroups {
            if group.contains(lastChar1), group.contains(lastChar2) {
                return true
            }
        }

        return lastChar1 == lastChar2
    }

    private func hasCiRhythmicPatterns(_ lines: [String]) -> Bool {
        print("\nChecking Ci rhythmic patterns:")
        // Common patterns in "Ci" where short and long lines alternate
        var alternatingLengthCount = 0
        if lines.count >= 4 {
            for i in 0 ..< (lines.count - 1) {
                let currentLength = lines[i].count
                let nextLength = lines[i + 1].count
                let diff = abs(currentLength - nextLength)
                if diff >= 2 {
                    print(
                        "Found alternating length: \(currentLength) vs \(nextLength) (diff: \(diff))"
                    )
                    alternatingLengthCount += 1
                }
            }
        }

        // Check if the text contains typical Ci ending patterns
        let commonCiEndings = ["年华", "天涯", "人家", "归去", "归来", "何处", "何方", "相思", "情怀"]
        let text = lines.joined()
        let matchedEndings = commonCiEndings.filter { text.contains($0) }
        let hasTypicalEnding = !matchedEndings.isEmpty

        if hasTypicalEnding {
            print("Found typical Ci endings: \(matchedEndings.joined(separator: ", "))")
        }

        // Calculate ratio of alternating lengths
        let alternatingRatio = Double(alternatingLengthCount) / Double(max(1, lines.count - 1))
        print("Alternating length ratio: \(String(format: "%.2f", alternatingRatio))")

        let result = (alternatingRatio > 0.4 && lines.count >= 4) || hasTypicalEnding
        print("Rhythmic pattern check result: \(result ? "✅" : "❌")")
        return result
    }

    private func hasClassicalPoetrySpecificMarkers() -> Bool {
        ClassicalChineseFeatures.poetryMarkers.contains { contains($0) }
    }

    private func hasClassicalCiSpecificMarkers() -> Bool {
        ClassicalChineseFeatures.ciMarkers.contains { contains($0) }
    }

    private func calculateLinguisticFeatureRatio(for features: [String]) -> Double {
        let cleanText = removePunctuation().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return 0.0 }

        var featureCount = 0
        let totalChars = cleanText.count

        // Count features
        for char in cleanText where features.contains(String(char)) {
            featureCount += 1
        }

        // Calculate ratio
        return Double(featureCount) / Double(totalChars)
    }

    // MARK: - Feature Detection Methods

    private func hasHighClassicalLinguisticFeatureRatio(_ threshold: Double = 0.15) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalChineseFeatures.linguistic)
        print("Classical linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }

    private func hasHighModernLinguisticFeatureRatio(_ threshold: Double = 0.2) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalChineseFeatures.modern)
        print("Modern linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }
}

// MARK: - String Utility Extensions

extension String {
    func removePunctuation() -> String {
        components(separatedBy: .punctuationCharacters).joined()
    }

    func removePunctuation2() -> String {
        let pattern = "[\\p{P}]"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count),
            withTemplate: ""
        )
    }
}
