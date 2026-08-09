//
//  GrammarAnalysisService+Prompt.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

import Foundation

extension GrammarAnalysisService {
    func ieltsRewriteLabels(answerLanguage: Language) -> (
        minimal: String,
        higherBand: String
    ) {
        (
            localizedAnswerString(
                forKey: "grammar.analysis.ielts.rewrite.minimal",
                answerLanguage: answerLanguage
            ),
            localizedAnswerString(
                forKey: "grammar.analysis.ielts.rewrite.higher_band",
                answerLanguage: answerLanguage
            )
        )
    }

    func ieltsRiskLabels(answerLanguage: Language) -> (
        high: String,
        medium: String,
        low: String
    ) {
        (
            localizedAnswerString(
                forKey: "grammar.analysis.ielts.risk.high",
                answerLanguage: answerLanguage
            ),
            localizedAnswerString(
                forKey: "grammar.analysis.ielts.risk.medium",
                answerLanguage: answerLanguage
            ),
            localizedAnswerString(
                forKey: "grammar.analysis.ielts.risk.low",
                answerLanguage: answerLanguage
            )
        )
    }

    func analysisSystemPrompt(answerLanguage: Language) -> String {
        let titles = analysisSectionTitles(answerLanguage: answerLanguage)
        let rewriteLabels = ieltsRewriteLabels(answerLanguage: answerLanguage)
        let riskLabels = ieltsRiskLabels(answerLanguage: answerLanguage)
        return switch analysisMode {
        case .general:
            """
            You are an expert grammar tutor inside a dictionary application.
            Focus on syntax, sentence structure, clause relations, word roles, \
            tense, voice, modality, omission, and fixed constructions.
            Keep the explanation concise, practical, and easy to scan.
            Only return Markdown content. Do not wrap the answer in code fences.
            """
        case .ielts:
            """
            You are an IELTS grammar coach inside a dictionary application.
            When the source text is English, assess it through IELTS \
            Grammatical Range and Accuracy first, then explain the structure in \
            plain terms.
            First decide whether the sample is closer to IELTS Writing or \
            Speaking. Make that judgment briefly in the first section.
            Separate grammar range from accuracy: comment on sentence variety, \
            clause control, and whether errors are frequent enough to reduce \
            clarity or band score.
            Prioritize only the issues that matter most for IELTS band \
            performance. For each issue, use the visible label \
            "\(riskLabels.high)", "\(riskLabels.medium)", or \
            "\(riskLabels.low)".
            Distinguish among: actual grammar errors, acceptable but unnatural \
            phrasing, and higher-band alternatives.
            Do not invent grammar faults just to fill the band-risk section. \
            If the sentence is already accurate and mature, say so clearly and \
            keep the risk section empty or limited to \
            "\(riskLabels.low)" points.
            Do not label a natural fixed expression as a grammar problem \
            merely because it can be rephrased.
            Unless the evidence is unusually strong, do not guess a specific \
            IELTS task number such as Task 1 or Task 2. Prefer broader labels \
            such as closer to IELTS Writing or closer to IELTS Speaking.
            In the structure section, explain functions and relationships more \
            than copying long stretches of the original sentence. Quote only \
            short fragments when necessary.
            Never add meta labels such as "中文解释", "Chinese explanation", \
            or similar commentary wrappers after the rewrite.
            Keep the tone practical and teacher-like, not robotic. Give \
            concise rewrites that sound natural in academic or spoken English, \
            depending on the sample.
            When the source text is not English, fall back to concise general \
            grammar analysis and only add an IELTS-style English rewrite when \
            it is genuinely useful.
            Use the following example only as style guidance. Always obey the \
            requested answer language and exact section titles from the user \
            prompt.

            Example input:
            I goes to library yesterday because I need finish my assignment.

            Example output:
            \(titles.judgment)
            Closer to IELTS Writing than Speaking because it attempts a formal \
            explanatory sentence. Grammatical Range is limited: the sentence \
            mainly uses one simple cause pattern. Accuracy is weakened by \
            several basic verb-form errors.

            \(titles.breakdown)
            The sentence has a simple main statement followed by a reason \
            clause introduced by "because". The relationship is clear, but \
            both parts show weak verb control, so the structure is basic and \
            error-prone rather than flexible.

            \(titles.focus)
            - \(riskLabels.high): "I goes" should be "I went" because \
            "yesterday" requires a \
            past-tense verb.
            - \(riskLabels.high): "need finish" should be "needed to finish" \
            or "need to \
            finish".
            - \(riskLabels.medium): "to library" is unnatural here; \
            "to the library" is \
            more natural.

            \(titles.rewrite)
            \(rewriteLabels.minimal): I went to the library yesterday because I \
            needed to finish my assignment.
            \(rewriteLabels.higherBand): I went to the library yesterday to finish my \
            assignment.

            Example input:
            While it is widely acknowledged that the rapid advancement of \
            artificial intelligence has the potential to revolutionize various \
            industries, it is also argued by many experts that this \
            technological progress could exacerbate existing social \
            inequalities unless governments implement comprehensive regulatory \
            frameworks to ensure equitable access and mitigate potential job \
            displacement.

            Example output:
            \(titles.judgment)
            Closer to IELTS Writing than Speaking because the sentence is \
            dense, formal, and argumentative. Grammatical Range is strong: it \
            controls subordination and a conditional idea within one sentence. \
            Accuracy is also strong, with no major band-limiting grammar \
            errors.

            \(titles.breakdown)
            The sentence opens with a concessive frame and then moves to the \
            writer's main claim. It combines two passive reporting structures \
            and finishes with an "unless" condition, showing controlled \
            subordination across the whole sentence.

            \(titles.focus)
            - \(riskLabels.low): The sentence is grammatically sound overall. \
            The main \
            improvement area is concision rather than correction.

            \(titles.rewrite)
            \(rewriteLabels.minimal): No major grammar correction is needed.
            \(rewriteLabels.higherBand): While the rapid advancement of artificial \
            intelligence is widely acknowledged as transformative, many \
            experts argue that it could deepen social inequalities unless \
            governments establish comprehensive regulatory frameworks to \
            ensure equitable access and reduce job displacement.

            Only return Markdown content. Do not wrap the answer in code fences.
            """
        }
    }

    func fetchGrammarAnalysis(
        for text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws
        -> String {
        let answerLanguage = analysisAnswerLanguage(targetLanguage: targetLanguage)
        let userPrompt = analysisPrompt(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            answerLanguage: answerLanguage
        )

        let response = try await requestChatCompletion(
            messages: [
                .init(
                    role: "system",
                    content: analysisSystemPrompt(answerLanguage: answerLanguage)
                ),
                .init(role: "user", content: userPrompt),
            ],
            model: model,
            temperature: temperature
        )
        return cleanMarkdownResponse(response)
    }

    func analysisLastSectionRequirement(
        sourceLanguage: Language,
        targetLanguage: Language,
        answerLanguage: Language
    )
        -> String {
        switch analysisMode {
        case .general:
            return """
            In the last section, provide either a natural \
            \(targetLanguage.queryLanguageName) translation or a corrected \
            version only when it is genuinely useful.
            """
        case .ielts:
            if sourceLanguage == .english {
                let rewriteLabels = ieltsRewriteLabels(answerLanguage: answerLanguage)
                return """
                In the last section, keep the explanation in \
                \(answerLanguage.rawValue). Use "\(rewriteLabels.minimal)" and \
                "\(rewriteLabels.higherBand)" as the two rewrite labels, but \
                keep the sentence content after those labels in English only. \
                Do not translate the rewrite sentences into \
                \(targetLanguage.queryLanguageName). Do not add any extra \
                explanation line after the rewrites.
                """
            }

            return """
            In the last section, add an IELTS-style English rewrite only when \
            it is genuinely useful, and do not add any extra explanation line \
            after the rewrite.
            """
        }
    }

    func analysisModeSpecificRequirements(answerLanguage: Language) -> String {
        switch analysisMode {
        case .general:
            return ""
        case .ielts:
            let riskLabels = ieltsRiskLabels(answerLanguage: answerLanguage)
            return """
            7. In the first section, state briefly whether the sample is closer \
            to IELTS Writing or Speaking, and why.
            8. In the third section, list only the most important band risks. \
            Mark each point with the label "\(riskLabels.high)", \
            "\(riskLabels.medium)", or "\(riskLabels.low)". If there is no \
            major band-limiting grammar problem, say that clearly and keep this \
            section empty or "\(riskLabels.low)" only.
            9. Distinguish clearly between grammar errors, acceptable but \
            unnatural phrasing, and stronger higher-band alternatives.
            10. In the last section, prefer a two-step rewrite when useful: \
            first a minimal correction, then a higher-band English version.
            11. Do not invent errors for natural fixed expressions or \
            grammatically sound advanced sentences just to make the critique \
            look fuller.
            12. In the structure section, do not paste long spans of the \
            original sentence. Explain how the sentence works, and quote only \
            short fragments when necessary.
            13. If the source text is English, the actual rewrite lines must \
            stay in English even when the explanation language is Chinese.
            14. Do not append extra labels or commentary wrappers such as \
            "中文解释" after the rewrite.
            """
        }
    }

    func analysisPrompt(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        answerLanguage: Language
    )
        -> String {
        let mode = analysisMode
        let sectionTitles = analysisSectionTitles(answerLanguage: answerLanguage)
        let lastSectionRequirement = analysisLastSectionRequirement(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            answerLanguage: answerLanguage
        )
        let extraRequirements = analysisModeSpecificRequirements(
            answerLanguage: answerLanguage
        )

        return """
        Analyze the following \(sourceLanguage.queryLanguageName) text for a \
        dictionary app user.

        Text:
        \"\"\"\(text)\"\"\"

        Requirements:
        1. Answer in \(answerLanguage.rawValue).
        2. Use the \(mode.promptLabel) mode.
        3. Use Markdown with these exact section titles:
           \(sectionTitles.judgment)
           \(sectionTitles.breakdown)
           \(sectionTitles.focus)
           \(sectionTitles.rewrite)
        4. If the text is a phrase instead of a full sentence, explain the \
        internal structure briefly instead of pretending it is complete.
        5. \(lastSectionRequirement)
        6. Keep the whole answer within 450 words.
        \(extraRequirements)
        """
    }
}
