//
//  GrammarAnalysisService+SectionTitles.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

extension GrammarAnalysisService {
    func analysisSectionTitles(answerLanguage: Language) -> (
        judgment: String,
        breakdown: String,
        focus: String,
        rewrite: String
    ) {
        switch analysisMode {
        case .general:
            (
                localizedAnswerString(
                    forKey: "grammar.analysis.general.section.judgment",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.general.section.breakdown",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.general.section.focus",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.general.section.rewrite",
                    answerLanguage: answerLanguage
                )
            )
        case .ielts:
            (
                localizedAnswerString(
                    forKey: "grammar.analysis.ielts.section.judgment",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.ielts.section.breakdown",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.ielts.section.focus",
                    answerLanguage: answerLanguage
                ),
                localizedAnswerString(
                    forKey: "grammar.analysis.ielts.section.rewrite",
                    answerLanguage: answerLanguage
                )
            )
        }
    }
}
