//
//  EasydictSwiftTests.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2023/12/23.
//  Copyright © 2023 izual. All rights reserved.
//

import XCTest

final class EasydictSwiftTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testAES() {
        let text = "123"
        let encryptedText = text.encryptAES()
        let decryptedText = encryptedText.decryptAES()
        XCTAssert(decryptedText == text)
    }
    
//    func testRemoveQuotes() throws {
//        let text =
//                """
//                \"\"\"
//                创造力就是让智慧尽情玩耍。——爱因斯坦
//                \"\"\"
//                """ 
//        let nsText = text as NSString
//        
//        let newText =  nsText.tryToRemoveQuotes().trim()
//         XCTAssert(newText == "创造力就是让智慧尽情玩耍。——爱因斯坦")
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
