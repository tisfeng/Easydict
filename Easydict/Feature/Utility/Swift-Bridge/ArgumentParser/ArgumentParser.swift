//
//  ArgumentParser.swift
//  Easydict
//
//  Created by tisfeng on 2023/5/30.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import ArgumentParser

@objcMembers public class MyArgumentParser: NSObject, ParsableCommand {
    public var arguments: [String] = [] // 添加一个公共属性
    
    required public override init() {
        super.init()
        count = 3
        includeCounter = false
        phrase = "Hello"

    }
    
    // repeat hello --count 3
    
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter = false
    
    @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
    var count: Int? = nil
    
    @Argument(help: "The phrase to repeat.")
    public var phrase: String
    
    public func run() throws {
        let repeatCount = count ?? 2
        
        for i in 1...repeatCount {
            if includeCounter {
                print("\(i): \(phrase)")
            } else {
                print(phrase)
            }
        }
    }
}

