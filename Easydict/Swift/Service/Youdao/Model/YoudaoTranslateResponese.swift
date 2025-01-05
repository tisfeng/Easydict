//
//  YoudaoTranslateResponese.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - YoudaoTranslateResponse

struct YoudaoTranslateResponse: Codable {
    struct TranslateResultItem: Codable {
        let src: String
        let tgt: String
        let tgtPronounce: String?
        let srcPronounce: String?
    }

    let translateResult: [[TranslateResultItem]]
    let type: String // en2zh-CHS
    let code: Int
}

/**
 {
   "code": 0,
   "dictResult": {
     "ce": {
       "word": {
         "trs": [
           {
             "voice": "Spell+of+the+Fragrance&type=2",
             "#text": "Spell of the Fragrance",
             "#tran": "国色天香；"
           },
           {
             "voice": "national+beauty+and+heavenly+fragrance&type=2",
             "#text": "national beauty and heavenly fragrance",
             "#tran": "国色天香；"
           }
         ],
         "return-phrase": "国色天香"
       }
     }
   },
   "translateResult": [
     [
       {
         "tgt": "National beauty and heavenly fragrance",
         "src": "国色天香",
         "srcPronounce": "guó sè tiānxiāng"
       }
     ]
   ],
   "type": "zh-CHS2en"
 }
 */
