//
//  OCRMergeAnalyzer.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// An analyzer for determining OCR text merge strategies.
/// This class encapsulates the context and provides methods to analyze various merge conditions.
class OCRMergeAnalyzer {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(context: OCRMergeContext) {
        self.context = context
    }

    // MARK: Internal

    // MARK: - Main Analysis Method

    /// Analyzes the context and determines the most appropriate merge strategy.
    /// - Returns: The determined merge strategy for the current pair.
    func determineMergeStrategy() -> OCRMergeStrategy {
        // High-priority conditions should be checked first.
        if let strategy = sameLineJoinStrategy() {
            return strategy
        }
        if let strategy = dashJoinStrategy() {
            return strategy
        }
        if let strategy = bigFontSizeChangeStrategy() {
            return strategy
        }
        if let strategy = indentationStrategy() {
            return strategy
        }
        if let strategy = poetryAndBigLineSpacingStrategy() {
            return strategy
        }
        if let strategy = listStrategy() {
            return strategy
        }
        if let strategy = letterFormatStrategy() {
            return strategy
        }
        if let strategy = bigLineSpacingStrategy() {
            return strategy
        }
        if let strategy = chinesePairStrategy() {
            return strategy
        }
        if let strategy = differentXStrategy() {
            return strategy
        }
        if let strategy = sameXStrategy() {
            return strategy
        }
        if let strategy = bigLineSpacingAndFontSizeStrategy() {
            return strategy
        }

        // Default merge strategy.
        print("    🔗 Default merge - join with space or not by language")
        return .mergeStrategy(for: context.pair)
    }

    // MARK: Private

    private var context: OCRMergeContext

    // MARK: - Private Strategy Methods

    /// 1. Same line join strategy
    private func sameLineJoinStrategy() -> OCRMergeStrategy? {
        if !context.isNewLine {
            print("    🔗 Same line continuation - join with space")
            return .joinWithSpace
        }
        return nil
    }

    /// 2. Dash handling strategy
    private func dashJoinStrategy() -> OCRMergeStrategy? {
        context.dashMergeStrategy
    }

    /// 3. Font size change strategy
    private func bigFontSizeChangeStrategy() -> OCRMergeStrategy? {
        if context.hasBigDifferentFontSize {
            print("    🔤 Font size change detected")
            return .newParagraph
        }
        return nil
    }

    /// 4. Indentation strategy
    private func indentationStrategy() -> OCRMergeStrategy? {
        if context.hasBigIndentation {
            print("    📏 Big indentation detected")
            if !context.isPreviousLongText {
                print("    📏 Big indentation and previous line is not long text - new paragraph")
                return .newParagraph
            }
        }
        return nil
    }

    /// 5. Poetry and big line spacing strategy
    private func poetryAndBigLineSpacingStrategy() -> OCRMergeStrategy? {
        if context.hasVeryBigLineSpacing {
            print("    📏 Very big line spacing detected")
            if context.isPoetry {
                print("    📏 Very big line spacing in poetry - line break")
                return .newParagraph
            }
            if !context.isPreviousLongText {
                print("    📏 Previous line is not long text - new paragraph")
                return .newParagraph
            }
            if context.previousTextHasEndPunctuation, !context.isFirstCharLowercase {
                print(
                    "    📏 Previous line ends with punctuation and current starts with uppercase - new paragraph"
                )
                return .newParagraph
            }
        }
        if context.isPoetry {
            print("    🎭 Poetry detected - line break")
            return .lineBreak
        }
        return nil
    }

    /// 6. List strategy
    private func listStrategy() -> OCRMergeStrategy? {
        if context.isCurrentList {
            print("    📋 List pattern detected")

            if context.isFirstObservationList {
                if context.hasVeryBigLineSpacing {
                    print("    📋 List pattern with high line spacing - new paragraph")
                    return .newParagraph
                }
                if context.isEqualFirstLineX {
                    print("    📋 List pattern with equal X")
                    if context.hasPairIndentation {
                        print("    📋 List pattern with equal X and indentation - new paragraph")
                        return .newParagraph
                    }
                    if !context.hasBigLineSpacing {
                        print("    📋 No big line spacing - line break")
                        return .lineBreak
                    }
                } else {
                    print("    📋 List pattern with different X - new paragraph")
                    return .newParagraph
                }
            } else {
                if context.hasPairIndentation, !context.isEqualFirstLineX {
                    print("    📋 List pattern with indentation and different X - new paragraph")
                    return .newParagraph
                }

                if context.hasBigLineSpacing {
                    print("    📋 List pattern with big line spacing - new paragraph")
                    return .newParagraph
                }
            }

            if !context.isEqualPairX, context.isFirstHasIndentation {
                print(
                    "    📋 List pattern with different X and first observation has indentation - new paragraph"
                )
                return .newParagraph
            }
            if context.isPrevHasIndentation, !context.isEqualFirstLineX {
                print("    📋 List pattern with previous indentation - new paragraph")
                return .newParagraph
            }
            print("    📋 List pattern - line break")
            return .lineBreak
        }
        return nil
    }

    /// 7. Letter format strategy (distance too far)
    private func letterFormatStrategy() -> OCRMergeStrategy? {
        /**
         Special case:

         If text is a letter format, we may need new paragraph when the distance between
         previous and current line is too far.

         If `distance` > 0.45, means it may need line break, or treat as new paragraph.

         Example:

         ```
                                    Wednesday, 4 Octobre 1950
         My dearest Nelson,
         ```
         */

        if context.isPreviousLongText {
            if context.distanceXRatio > 0.45 {
                print("    📄 Letter format detected - new paragraph")
                return .newParagraph
            }
        }
        return nil
    }

    /// 8. Big line spacing strategy
    private func bigLineSpacingStrategy() -> OCRMergeStrategy? {
        if context.hasBigLineSpacing {
            let shouldJoin =
                context.isPreviousLongText && context.isFirstCharLowercase && !context.isCurrentList
            if shouldJoin {
                print("    📄 Page continuation detected - join with space")
                return .mergeStrategy(for: context.pair)
            } else {
                print("    📏 Big line spacing - new paragraph")
                return .newParagraph
            }
        }
        return nil
    }

    /// 9. Chinese pair and classical Chinese special handling
    private func chinesePairStrategy() -> OCRMergeStrategy? {
        /**
         又到绿杨曾折处，不语垂鞭，踏遍清秋路。衰草连天无意绪，雁声远向萧关去。
         不恨天涯行役苦，只恨西风，吹梦成今古。明日客程还几许，沾衣况是新寒雨。
         */
        if context.isEqualChinesePair {
            print("    🔗 Equal Chinese pair - line break")
            return .lineBreak
        }

        /**
         郁孤台下清江水，中间多少行人泪。西北望长安，可怜无数山。
         青山遮不住，毕竟东流去。江晚正愁余，山深闻鹧鸪。
         */
        if context.isClassicalChinese {
            if context.isPreviousLongText, context.previousTextHasEndPunctuation,
               !context.isPrevHasIndentation, context.isEqualPairX {
                print("    🎭 Classical Chinese long text with end punctuation - line break")
                return .lineBreak
            }
        }
        return nil
    }

    /// 10. Different X handling
    private func differentXStrategy() -> OCRMergeStrategy? {
        if !context.isEqualPairX {
            print("    🔗 Different X detected")
            if !context.isPreviousLongText {
                print("    🔗 Different X and previous line is not long text - new paragraph")
                return .newParagraph
            }

            if !context.isPrevAbsoluteLongText {
                print("    🔗 Previous line is NOT absolute long text")
                if context.isPrevHasIndentation {
                    print("    🔗 Different X and previous line has indentation - new paragraph")
                    return .newParagraph
                }
                if context.isPreviousList {
                    print("    🔗 Different X and previous line is a list - new paragraph")
                    return .newParagraph
                }
                if context.hasBigIndentation {
                    print("    🔗 Different X and has big indentation - new paragraph")
                    return .newParagraph
                }
                print("    🔗 Different X and previous line is not absolute long text - line break")
                return .lineBreak
            } else {
                // Different X, and previous line is absolute long text

                /**
                 Special case:

                 If different X, previous line is a list and long, current line has pair indentation,
                 it may be not a new paragraph.

                 Example:

                 ```
                 The rules are as follows:

                 1. I am a girl with severe depression
                    and severe anxiety.
                 2. I am the second daughter in my
                    family, 10 years younger than my
                 ```
                 */

                if context.hasPairIndentation, !context.isPreviousList {
                    print(
                        "    🔗 Has pair indentation, previous line is absolute long and NOT list - new paragraph"
                    )
                    return .newParagraph
                }

                /**
                 Special case:

                 If has different X,  previous and current line both have indentation,
                 we should not join them, because it may be a new paragraph.

                 Example:

                 ```
                                V. SECURITY CHALLENGES AND OPPORTUNITIES
                    In the following, we discuss existing security challenges
                 and shed light on possible security opportunities and research
                 ```
                 */

                if context.hasIndentation, context.isPrevHasIndentation, !context.hasPairIndentation {
                    print(
                        "    🔗 Different X, previous and current line both have indentation - new paragraph"
                    )
                    return .newParagraph
                }
                print(
                    "    🔗 Different X and previous line is absolute long text - join with space or not by language"
                )
                return .mergeStrategy(for: context.pair)
            }
        }
        return nil
    }

    /// 11. Same X handling
    private func sameXStrategy() -> OCRMergeStrategy? {
        if context.isEqualPairX {
            print("    🔗 Same X detected")

            /**
             Special case: Check if need new paragraph when previous is a list.

             ```
                   III. IMPLICATIONS OF HTTP/2 FEATURES ON 5G SBA
                   HTTP/2 introduces multiple features that we explore
             hereafter and discuss the security impact of their possible
             ```
             */
            if context.isPreviousList {
                if context.mayBeNewParagraph, !context.isFirstCharLowercase {
                    print(
                        "  📋 Previous is list and may be new paragraph, and current is not lowercase - new paragraph"
                    )
                    return .newParagraph
                }
            }

            if !context.isPreviousLongText {
                print("    🔗 Previous line is not long text - line break or new paragraph")
                return lineBreakOrParagraph(context.mayBeNewParagraph)
            } else {
                let shouldLineBreak =
                    context.previous == context.firstObservation && !context.isPrevHasIndentation
                        && !context.isPrevAbsoluteLongText
                if shouldLineBreak {
                    print(
                        "    🔗 Previous is first observation and short - line break or new paragraph"
                    )
                    return lineBreakOrParagraph(context.mayBeNewParagraph)
                }

                // Handle too short lines
                if context.isShortLine, context.isPreviousShortLine {
                    print("    🎭 Short line pattern - line break")
                    return .lineBreak
                }
            }
        }
        return nil
    }

    /// 12. Big line spacing & font size change together
    private func bigLineSpacingAndFontSizeStrategy() -> OCRMergeStrategy? {
        if context.hasBigLineSpacingRelaxed, context.hasDifferentFontSizeRelaxed {
            print("    📏 Big line spacing and different font size - new paragraph")
            return .newParagraph
        }
        return nil
    }

    // MARK: - Helper Methods

    /// Determines whether to use a line break or start a new paragraph based on the context.
    private func lineBreakOrParagraph(_ shouldStartNewParagraph: Bool) -> OCRMergeStrategy {
        shouldStartNewParagraph ? .newParagraph : .lineBreak
    }
}
