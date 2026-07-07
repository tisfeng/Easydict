//
//  GrammarAnalysisService+SectionTitles.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

import Foundation

// swiftlint:disable function_body_length

extension GrammarAnalysisService {
    func analysisSectionTitles(answerLanguage: Language) -> (
        judgment: String,
        breakdown: String,
        focus: String,
        rewrite: String
    ) {
        switch analysisMode {
        case .general:
            generalSectionTitles(answerLanguage: answerLanguage)
        case .ielts:
            ieltsSectionTitles(answerLanguage: answerLanguage)
        }
    }

    func generalSectionTitles(answerLanguage: Language) -> (
        judgment: String,
        breakdown: String,
        focus: String,
        rewrite: String
    ) {
        switch answerLanguage {
        case .classicalChinese, .simplifiedChinese, .traditionalChinese:
            ("## 结构判断", "## 成分拆解", "## 关键语法点", "## 自然译法")
        case .english:
            ("## Structure", "## Breakdown", "## Key Grammar Points", "## Natural Translation")
        case .japanese:
            ("## 構造判断", "## 成分分解", "## 重要な文法ポイント", "## 自然な訳し方")
        case .korean:
            ("## 구조 판단", "## 성分 분석", "## 핵심 문법 포인트", "## 자연스러운 번역")
        case .french:
            ("## Structure", "## Décomposition", "## Points grammaticaux clés", "## Traduction naturelle")
        case .spanish:
            ("## Estructura", "## Desglose", "## Puntos gramaticales clave", "## Traducción natural")
        case .catalan:
            ("## Estructura", "## Desglossament", "## Punts gramaticals clau", "## Traducció natural")
        case .brazilianPortuguese, .portuguese:
            ("## Estrutura", "## Análise detalhada", "## Pontos gramaticais-chave", "## Tradução natural")
        case .italian:
            ("## Struttura", "## Scomposizione", "## Punti grammaticali chiave", "## Traduzione naturale")
        case .german:
            ("## Struktur", "## Aufschlüsselung", "## Zentrale Grammatikpunkte", "## Natürliche Übersetzung")
        case .russian:
            ("## Структура", "## Разбор", "## Ключевые грамматические моменты", "## Естественный перевод")
        case .arabic:
            ("## البنية", "## التفكيك", "## النقاط النحوية الأساسية", "## ترجمة طبيعية")
        case .swedish:
            ("## Struktur", "## Genomgång", "## Viktiga grammatikpunkter", "## Naturlig översättning")
        case .romanian:
            ("## Structură", "## Descompunere", "## Puncte gramaticale cheie", "## Traducere naturală")
        case .thai:
            ("## โครงสร้าง", "## การแยกส่วน", "## ประเด็นไวยากรณ์สำคัญ", "## คำแปลธรรมชาติ")
        case .slovak:
            ("## Štruktúra", "## Rozbor", "## Kľúčové gramatické body", "## Prirodzený preklad")
        case .dutch:
            ("## Structuur", "## Uitsplitsing", "## Belangrijke grammaticale punten", "## Natuurlijke vertaling")
        case .hungarian:
            ("## Szerkezet", "## Elemzés", "## Kulcsfontosságú nyelvtani pontok", "## Természetes fordítás")
        case .greek:
            ("## Δομή", "## Ανάλυση", "## Βασικά γραμματικά σημεία", "## Φυσική μετάφραση")
        case .danish:
            ("## Struktur", "## Gennemgang", "## Centrale grammatikpunkter", "## Naturlig oversættelse")
        case .finnish:
            ("## Rakenne", "## Erittely", "## Keskeiset kielioppikohdat", "## Luonteva käännös")
        case .polish:
            ("## Struktura", "## Analiza", "## Kluczowe zagadnienia gramatyczne", "## Naturalne tłumaczenie")
        case .czech:
            ("## Struktura", "## Rozbor", "## Klíčové gramatické body", "## Přirozený překlad")
        case .turkish:
            ("## Yapı", "## Çözümleme", "## Temel dil bilgisi noktaları", "## Doğal çeviri")
        case .lithuanian:
            ("## Struktūra", "## Skaidymas", "## Pagrindiniai gramatikos aspektai", "## Natūralus vertimas")
        case .latvian:
            ("## Struktūra", "## Izklāsts", "## Galvenie gramatikas punkti", "## Dabisks tulkojums")
        case .ukrainian:
            ("## Структура", "## Розбір", "## Ключові граматичні моменти", "## Природний переклад")
        case .bulgarian:
            ("## Структура", "## Разбор", "## Ключови граматични точки", "## Естествен превод")
        case .indonesian:
            ("## Struktur", "## Rincian", "## Poin tata bahasa kunci", "## Terjemahan alami")
        case .malay:
            ("## Struktur", "## Pecahan", "## Poin tatabahasa utama", "## Terjemahan semula jadi")
        case .slovenian:
            ("## Struktura", "## Razčlenitev", "## Ključne slovnične točke", "## Naraven prevod")
        case .estonian:
            ("## Struktuur", "## Jaotus", "## Peamised grammatikapunktid", "## Loomulik tõlge")
        case .vietnamese:
            ("## Cấu trúc", "## Phân tích", "## Điểm ngữ pháp chính", "## Bản dịch tự nhiên")
        case .persian:
            ("## ساختار", "## تجزیه‌وتحلیل", "## نکات کلیدی دستور زبان", "## ترجمه طبیعی")
        case .hindi:
            ("## संरचना", "## विश्लेषण", "## मुख्य व्याकरण बिंदु", "## स्वाभाविक अनुवाद")
        case .telugu:
            ("## నిర్మాణం", "## విశ్లేషణ", "## ముఖ్య వ్యాకరణ అంశాలు", "## సహజ అనువాదం")
        case .tamil:
            ("## கட்டமைப்பு", "## பகுப்பாய்வு", "## முக்கிய இலக்கண அம்சங்கள்", "## இயல்பான மொழிபெயர்ப்பு")
        case .urdu:
            ("## ساخت", "## تجزیہ", "## اہم قواعدی نکات", "## فطری ترجمہ")
        case .filipino:
            ("## Estruktura", "## Paghimay", "## Mahahalagang punto sa gramatika", "## Likas na salin")
        case .khmer:
            ("## រចនាសម្ព័ន្ធ", "## ការវិភាគ", "## ចំណុចវេយ្យាករណ៍សំខាន់ៗ", "## ការបកប្រែធម្មជាតិ")
        case .lao:
            ("## ໂຄງສ້າງ", "## ການວິເຄາະ", "## ຈຸດໄວຍາກອນສຳຄັນ", "## ຄຳແປທຳມະຊາດ")
        case .bengali:
            ("## গঠন", "## বিশ্লেষণ", "## প্রধান ব্যাকরণ পয়েন্ট", "## স্বাভাবিক অনুবাদ")
        case .burmese:
            ("## ဖွဲ့စည်းပုံ", "## ခွဲခြမ်းစိတ်ဖြာမှု", "## အရေးကြီးသော သဒ္ဒါအချက်များ", "## သဘာဝကျသော ဘာသာပြန်")
        case .norwegian:
            ("## Struktur", "## Gjennomgang", "## Viktige grammatikkpunkter", "## Naturlig oversettelse")
        case .serbian:
            ("## Структура", "## Анализа", "## Кључне граматичке тачке", "## Природан превод")
        case .croatian:
            ("## Struktura", "## Analiza", "## Ključne gramatičke točke", "## Prirodan prijevod")
        case .mongolian:
            ("## Бүтэц", "## Задлан шинжилгээ", "## Гол дүрмийн цэгүүд", "## Байгалийн орчуулга")
        case .hebrew:
            ("## מבנה", "## פירוק", "## נקודות דקדוק מרכזיות", "## תרגום טבעי")
        case .georgian:
            ("## სტრუქტურა", "## ანალიზი", "## ძირითადი გრამატიკული პუნქტები", "## ბუნებრივი თარგმანი")
        case .uyghur:
            ("## قۇرۇلما", "## تەھلىل", "## مۇھىم گرامماتىكا نۇقتىلىرى", "## تەبىئىي تەرجىمە")
        case .auto, .unsupported:
            ("## Structure", "## Breakdown", "## Key Grammar Points", "## Natural Translation")
        default:
            ("## Structure", "## Breakdown", "## Key Grammar Points", "## Natural Translation")
        }
    }

    func ieltsSectionTitles(answerLanguage: Language) -> (
        judgment: String,
        breakdown: String,
        focus: String,
        rewrite: String
    ) {
        switch answerLanguage {
        case .classicalChinese, .simplifiedChinese, .traditionalChinese:
            ("## 雅思视角", "## 结构拆解", "## 扣分风险", "## 更高分表达")
        case .english:
            ("## IELTS View", "## Structure Breakdown", "## Band Risks", "## Higher-Band Rewrite")
        case .japanese:
            ("## IELTS視点", "## 構造分析", "## 減点リスク", "## より高得点の表現")
        case .korean:
            ("## IELTS 관점", "## 구조 분석", "## 감점 위험", "## 고득점 표현")
        case .french:
            (
                "## Perspective IELTS",
                "## Analyse de la structure",
                "## Risques de perte de points",
                "## Reformulation de niveau supérieur"
            )
        case .spanish:
            (
                "## Enfoque IELTS",
                "## Análisis de la estructura",
                "## Riesgos de pérdida de puntos",
                "## Versión de mayor puntuación"
            )
        case .catalan:
            (
                "## Perspectiva IELTS",
                "## Anàlisi de l'estructura",
                "## Riscos de penalització",
                "## Versió de puntuació més alta"
            )
        case .brazilianPortuguese, .portuguese:
            (
                "## Perspectiva IELTS",
                "## Análise da estrutura",
                "## Riscos de perda de pontos",
                "## Versão de maior pontuação"
            )
        case .italian:
            (
                "## Prospettiva IELTS",
                "## Analisi della struttura",
                "## Rischi di penalizzazione",
                "## Versione di livello superiore"
            )
        case .german:
            ("## IELTS-Perspektive", "## Strukturanalyse", "## Abzugsrisiken", "## Ausdruck auf höherem Niveau")
        case .russian:
            ("## Взгляд IELTS", "## Разбор структуры", "## Риски потери баллов", "## Более сильная версия")
        case .arabic:
            ("## منظور آيلتس", "## تحليل البنية", "## مخاطر فقدان الدرجات", "## صياغة بدرجة أعلى")
        case .swedish:
            ("## IELTS-perspektiv", "## Strukturanalys", "## Risk för poängavdrag", "## Version på högre nivå")
        case .romanian:
            (
                "## Perspectivă IELTS",
                "## Analiza structurii",
                "## Riscuri de pierdere a punctelor",
                "## Versiune de nivel mai înalt"
            )
        case .thai:
            ("## มุมมอง IELTS", "## การวิเคราะห์โครงสร้าง", "## ความเสี่ยงต่อการเสียคะแนน", "## เวอร์ชันคะแนนสูงขึ้น")
        case .slovak:
            ("## Pohľad IELTS", "## Analýza štruktúry", "## Riziká straty bodov", "## Verzia na vyššej úrovni")
        case .dutch:
            ("## IELTS-perspectief", "## Structuuranalyse", "## Risico op puntenverlies", "## Versie op hoger niveau")
        case .hungarian:
            ("## IELTS-nézőpont", "## Szerkezeti elemzés", "## Pontlevonási kockázatok", "## Magasabb szintű változat")
        case .greek:
            ("## Οπτική IELTS", "## Ανάλυση δομής", "## Κίνδυνοι απώλειας βαθμών", "## Εκδοχή υψηλότερου επιπέδου")
        case .danish:
            ("## IELTS-perspektiv", "## Strukturanalyse", "## Risiko for pointtab", "## Version på højere niveau")
        case .finnish:
            ("## IELTS-näkökulma", "## Rakenteen analyysi", "## Pistevähennysriskit", "## Korkeamman tason versio")
        case .polish:
            (
                "## Perspektywa IELTS",
                "## Analiza struktury",
                "## Ryzyko utraty punktów",
                "## Wersja na wyższym poziomie"
            )
        case .czech:
            ("## Pohled IELTS", "## Analýza struktury", "## Rizika ztráty bodů", "## Verze na vyšší úrovni")
        case .turkish:
            ("## IELTS bakışı", "## Yapı analizi", "## Puan kaybı riskleri", "## Daha yüksek düzeyli ifade")
        case .lithuanian:
            ("## IELTS požiūris", "## Struktūros analizė", "## Balų praradimo rizikos", "## Aukštesnio lygio versija")
        case .latvian:
            ("## IELTS skatījums", "## Struktūras analīze", "## Punktu zaudēšanas riski", "## Augstāka līmeņa versija")
        case .ukrainian:
            ("## Погляд IELTS", "## Аналіз структури", "## Ризики втрати балів", "## Версія вищого рівня")
        case .bulgarian:
            (
                "## Гледна точка IELTS",
                "## Анализ на структурата",
                "## Рискове от загуба на точки",
                "## Версия на по-високо ниво"
            )
        case .indonesian:
            (
                "## Perspektif IELTS",
                "## Analisis struktur",
                "## Risiko kehilangan poin",
                "## Versi dengan skor lebih tinggi"
            )
        case .malay:
            (
                "## Perspektif IELTS",
                "## Analisis struktur",
                "## Risiko kehilangan markah",
                "## Versi bertahap lebih tinggi"
            )
        case .slovenian:
            ("## Pogled IELTS", "## Analiza strukture", "## Tveganja za izgubo točk", "## Različica na višji ravni")
        case .estonian:
            ("## IELTS-i vaade", "## Struktuuri analüüs", "## Punktikaotuse riskid", "## Kõrgema taseme versioon")
        case .vietnamese:
            ("## Góc nhìn IELTS", "## Phân tích cấu trúc", "## Rủi ro mất điểm", "## Phiên bản điểm cao hơn")
        case .persian:
            ("## دیدگاه آیلتس", "## تحلیل ساختار", "## ریسک از دست دادن نمره", "## نسخه با سطح بالاتر")
        case .hindi:
            ("## आईईएलटीएस दृष्टिकोण", "## संरचना विश्लेषण", "## अंक कटने के जोखिम", "## उच्च स्तर का संस्करण")
        case .telugu:
            ("## IELTS దృక్కోణం", "## నిర్మాణ విశ్లేషణ", "## మార్కులు కోల్పోయే ప్రమాదాలు", "## ఉన్నత స్థాయి సంస్కరణ")
        case .tamil:
            ("## IELTS பார்வை", "## கட்டமைப்பு பகுப்பாய்வு", "## மதிப்பெண் இழப்பு அபாயங்கள்", "## உயர்ந்த நிலை பதிப்பு")
        case .urdu:
            ("## آئیلٹس نقطۂ نظر", "## ساخت کا تجزیہ", "## نمبر کم ہونے کے خطرات", "## اعلیٰ سطح کا نسخہ")
        case .filipino:
            (
                "## Pananaw sa IELTS",
                "## Pagsusuri ng estruktura",
                "## Mga panganib sa bawas-puntos",
                "## Mas mataas na antas na bersyon"
            )
        case .khmer:
            ("## ទស្សនៈ IELTS", "## ការវិភាគរចនាសម្ព័ន្ធ", "## ហានិភ័យនៃការបាត់ពិន្ទុ", "## កំណែកម្រិតខ្ពស់")
        case .lao:
            ("## ມຸມມອງ IELTS", "## ການວິເຄາະໂຄງສ້າງ", "## ຄວາມສ່ຽງຕໍ່ການເສຍຄະແນນ", "## ສະບັບລະດັບສູງ")
        case .bengali:
            ("## আইইএলটিএস দৃষ্টিভঙ্গি", "## গঠন বিশ্লেষণ", "## নম্বর হারানোর ঝুঁকি", "## উচ্চতর স্তরের সংস্করণ")
        case .burmese:
            ("## IELTS အမြင်", "## ဖွဲ့စည်းပုံ ခွဲခြမ်းစိတ်ဖြာမှု", "## အမှတ်လျော့နိုင်သည့် အန္တရာယ်များ", "## ပိုမိုမြင့်မားသည့် ဗားရှင်း")
        case .norwegian:
            ("## IELTS-perspektiv", "## Strukturanalyse", "## Risiko for poengtap", "## Versjon på høyere nivå")
        case .serbian:
            ("## IELTS перспектива", "## Анализа структуре", "## Ризици од губитка поена", "## Верзија вишег нивоа")
        case .croatian:
            ("## Perspektiva IELTS-a", "## Analiza strukture", "## Rizici gubitka bodova", "## Verzija više razine")
        case .mongolian:
            ("## IELTS-ийн өнцөг", "## Бүтцийн шинжилгээ", "## Оноо алдах эрсдэл", "## Илүү өндөр түвшний хувилбар")
        case .hebrew:
            ("## מבט IELTS", "## ניתוח מבנה", "## סיכוני אובדן נקודות", "## גרסה ברמה גבוהה יותר")
        case .georgian:
            (
                "## IELTS-ის ხედვა",
                "## სტრუქტურის ანალიზი",
                "## ქულების დაკარგვის რისკები",
                "## უფრო მაღალი დონის ვერსია"
            )
        case .uyghur:
            (
                "## IELTS نۇقتىئىنەزىرى",
                "## قۇرۇلما تەھلىلى",
                "## نومۇر يوقىتىش خەۋپى",
                "## تېخىمۇ يۇقىرى سەۋىيەلىك نۇسخا"
            )
        case .auto, .unsupported:
            ("## IELTS View", "## Structure Breakdown", "## Band Risks", "## Higher-Band Rewrite")
        default:
            ("## IELTS View", "## Structure Breakdown", "## Band Risks", "## Higher-Band Rewrite")
        }
    }
}

// swiftlint:enable function_body_length
