//
//  GrammarAnalysisService+SkipMessage.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

import Foundation

// swiftlint:disable line_length

extension GrammarAnalysisService {
    /// Returns a direct per-language skip message to keep the grammar-analysis
    /// card aligned with the current answer language instead of UI locale.
    func skipMessageText(answerLanguage: Language) -> String? {
        switch answerLanguage {
        case .classicalChinese, .simplifiedChinese:
            "当前文本过短，或不像适合做语法分析的自然语言内容，因此已跳过语法分析。"
        case .traditionalChinese:
            "目前文本過短，或不像適合做語法分析的自然語言內容，因此已略過語法分析。"
        case .english:
            "The current text is too short or does not look like analyzable natural language, so grammar analysis was skipped."
        case .japanese:
            "現在のテキストは短すぎるか、文法解析に適した自然言語に見えないため、文法解析をスキップしました。"
        case .korean:
            "현재 텍스트가 너무 짧거나 문법 분석에 적합한 자연어로 보이지 않아 문법 분석을 건너뛰었습니다."
        case .french:
            "Le texte actuel est trop court ou ne semble pas être un langage naturel pouvant faire l'objet d'une analyse grammaticale, donc l'analyse a été ignorée."
        case .spanish:
            "El texto actual es demasiado corto o no parece lenguaje natural apto para análisis gramatical, por lo que se omitió el análisis."
        case .catalan:
            "El text actual és massa curt o no sembla llenguatge natural apte per a l'anàlisi gramatical, de manera que s'ha omès l'anàlisi."
        case .brazilianPortuguese, .portuguese:
            "O texto atual é muito curto ou não parece linguagem natural adequada para análise gramatical, por isso a análise foi ignorada."
        case .italian:
            "Il testo attuale è troppo breve o non sembra un linguaggio naturale adatto all'analisi grammaticale, quindi l'analisi è stata saltata."
        case .german:
            "Der aktuelle Text ist zu kurz oder sieht nicht wie analysierbare natürliche Sprache aus, daher wurde die Grammatikanalyse übersprungen."
        case .russian:
            "Текущий текст слишком короткий или не похож на естественный язык, пригодный для грамматического анализа, поэтому анализ был пропущен."
        case .arabic:
            "النص الحالي قصير جدًا أو لا يبدو لغة طبيعية قابلة للتحليل النحوي، لذلك تم تخطي التحليل النحوي."
        case .swedish:
            "Den aktuella texten är för kort eller ser inte ut som naturligt språk som går att grammatikanalysera, så grammatikanalysen överhoppades."
        case .romanian:
            "Textul actual este prea scurt sau nu pare a fi limbaj natural potrivit pentru analiză gramaticală, astfel că analiza a fost omisă."
        case .thai:
            "ข้อความปัจจุบันสั้นเกินไป หรือดูไม่เหมือนภาษาธรรมชาติที่เหมาะสำหรับการวิเคราะห์ไวยากรณ์ จึงข้ามการวิเคราะห์ไวยากรณ์"
        case .slovak:
            "Aktuálny text je príliš krátky alebo nevyzerá ako prirodzený jazyk vhodný na gramatickú analýzu, preto bola analýza preskočená."
        case .dutch:
            "De huidige tekst is te kort of lijkt geen natuurlijke taal die grammaticaal analyseerbaar is, dus is de grammatica-analyse overgeslagen."
        case .hungarian:
            "A jelenlegi szöveg túl rövid, vagy nem tűnik nyelvtanilag elemezhető természetes nyelvnek, ezért a nyelvtani elemzés ki lett hagyva."
        case .greek:
            "Το τρέχον κείμενο είναι πολύ σύντομο ή δεν φαίνεται να είναι φυσική γλώσσα κατάλληλη για γραμματική ανάλυση, οπότε η ανάλυση παραλείφθηκε."
        case .danish:
            "Den aktuelle tekst er for kort eller ligner ikke naturligt sprog, der kan grammatikanalyseres, så grammatikanalysen blev sprunget over."
        case .finnish:
            "Nykyinen teksti on liian lyhyt tai ei näytä kieliopilliseen analyysiin sopivalta luonnolliselta kieleltä, joten analyysi ohitettiin."
        case .polish:
            "Obecny tekst jest zbyt krótki lub nie wygląda na naturalny język nadający się do analizy gramatycznej, więc analiza została pominięta."
        case .czech:
            "Aktuální text je příliš krátký nebo nevypadá jako přirozený jazyk vhodný pro gramatickou analýzu, proto byla analýza přeskočena."
        case .turkish:
            "Mevcut metin çok kısa ya da dil bilgisi açısından analiz edilebilecek doğal bir dil gibi görünmüyor, bu yüzden dil bilgisi analizi atlandı."
        case .lithuanian:
            "Dabartinis tekstas yra per trumpas arba neatrodo kaip natūrali kalba, tinkama gramatinei analizei, todėl analizė buvo praleista."
        case .latvian:
            "Pašreizējais teksts ir pārāk īss vai neizskatās pēc dabiskas valodas, ko var analizēt gramatiski, tāpēc analīze tika izlaista."
        case .ukrainian:
            "Поточний текст занадто короткий або не схожий на природну мову, придатну для граматичного аналізу, тому аналіз було пропущено."
        case .bulgarian:
            "Текущият текст е твърде кратък или не изглежда като естествен език, подходящ за граматичен анализ, затова анализът беше пропуснат."
        case .indonesian:
            "Teks saat ini terlalu pendek atau tidak tampak seperti bahasa alami yang layak dianalisis tata bahasanya, sehingga analisis dilewati."
        case .malay:
            "Teks semasa terlalu pendek atau tidak kelihatan seperti bahasa semula jadi yang sesuai untuk analisis tatabahasa, maka analisis dilangkau."
        case .slovenian:
            "Trenutno besedilo je prekratko ali pa ni videti kot naravni jezik, primeren za slovnično analizo, zato je bila analiza preskočena."
        case .estonian:
            "Praegune tekst on liiga lühike või ei näi olevat loomulik keel, mida saaks grammatiliselt analüüsida, seega analüüs jäeti vahele."
        case .vietnamese:
            "Văn bản hiện tại quá ngắn hoặc không giống ngôn ngữ tự nhiên phù hợp để phân tích ngữ pháp, vì vậy đã bỏ qua phân tích."
        case .persian:
            "متن فعلی خیلی کوتاه است یا شبیه زبان طبیعیِ قابل تحلیل از نظر دستور زبان نیست، بنابراین تحلیل دستور زبان نادیده گرفته شد."
        case .hindi:
            "वर्तमान पाठ बहुत छोटा है या व्याकरण विश्लेषण के लिए उपयुक्त प्राकृतिक भाषा जैसा नहीं लगता, इसलिए व्याकरण विश्लेषण छोड़ दिया गया।"
        case .telugu:
            "ప్రస్తుతం ఉన్న పాఠ్యం చాలా చిన్నదిగా ఉంది లేదా వ్యాకరణ విశ్లేషణకు సరిపోయే సహజ భాషలా కనిపించడం లేదు, కాబట్టి విశ్లేషణను దాటవేశారు."
        case .tamil:
            "தற்போதைய உரை மிகக் குறுகியது அல்லது இலக்கண பகுப்பாய்விற்கு ஏற்ற இயல்பான மொழியாகத் தெரியவில்லை; எனவே பகுப்பாய்வு தவிர்க்கப்பட்டது."
        case .urdu:
            "موجودہ متن بہت مختصر ہے یا ایسا قدرتی زبان متن نہیں لگتا جس کا قواعدی تجزیہ کیا جا سکے، اس لیے تجزیہ چھوڑ دیا گیا۔"
        case .filipino:
            "Masyadong maikli ang kasalukuyang teksto o hindi ito mukhang natural na wikang maaaring suriin sa gramatika, kaya nilaktawan ang pagsusuri."
        case .khmer:
            "អត្ថបទបច្ចុប្បន្នខ្លីពេក ឬមិនមើលទៅដូចជាភាសាធម្មជាតិដែលសមស្របសម្រាប់ការវិភាគវេយ្យាករណ៍ ដូច្នេះបានរំលងការវិភាគ។"
        case .lao:
            "ຂໍ້ຄວາມປະຈຸບັນສັ້ນເກີນໄປ ຫຼືບໍ່ເບິ່ງຄືພາສາທຳມະຊາດທີ່ເໝາະສຳລັບການວິເຄາະໄວຍາກອນ ດັ່ງນັ້ນຈຶ່ງຂ້າມການວິເຄາະ."
        case .bengali:
            "বর্তমান লেখাটি খুব ছোট, বা এটি ব্যাকরণ বিশ্লেষণের উপযোগী প্রাকৃতিক ভাষা বলে মনে হচ্ছে না, তাই বিশ্লেষণটি এড়িয়ে যাওয়া হয়েছে।"
        case .burmese:
            "လက်ရှိစာသားသည် အလွန်တိုလွန်းသည် သို့မဟုတ် သဒ္ဒါခွဲခြမ်းစိတ်ဖြာရန် သင့်တော်သော သဘာဝဘာသာစကားဟု မထင်ရသောကြောင့် ခွဲခြမ်းစိတ်ဖြာမှုကို ကျော်သွားခဲ့သည်။"
        case .norwegian:
            "Den nåværende teksten er for kort eller ser ikke ut som naturlig språk som kan analyseres grammatisk, så analysen ble hoppet over."
        case .serbian:
            "Тренутни текст је прекратак или не личи на природан језик погодан за граматичку анализу, па је анализа прескочена."
        case .croatian:
            "Trenutni tekst je prekratak ili ne izgleda kao prirodan jezik prikladan za gramatičku analizu, pa je analiza preskočena."
        case .mongolian:
            "Одоогийн текст хэт богино эсвэл дүрмийн хувьд шинжлэхэд тохирох байгалийн хэл шиг харагдахгүй тул шинжилгээг алгаслаа."
        case .hebrew:
            "הטקסט הנוכחי קצר מדי או שאינו נראה כשפה טבעית שניתן לנתח דקדוקית, ולכן הניתוח הדקדוקי דולג."
        case .georgian:
            "მიმდინარე ტექსტი ზედმეტად მოკლეა ან არ ჰგავს გრამატიკული ანალიზისთვის შესაბამის ბუნებრივ ენას, ამიტომ ანალიზი გამოტოვებულია."
        case .uyghur:
            "نۆۋەتتىكى تېكىست بەك قىسقا ياكى گرامماتىكىلىق تەھلىل قىلىشقا ماس كېلىدىغان تەبىئىي تىلدەك كۆرۈنمەيدۇ، شۇڭا تەھلىل ئاتلاپ ئۆتۈلدى."
        case .auto, .unsupported:
            nil
        default:
            nil
        }
    }
}

// swiftlint:enable line_length
