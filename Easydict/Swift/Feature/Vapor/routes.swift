//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "Easydict"
    }

    app.get("hello") { _ async -> String in
        "Hello, Welcome to Easydict!"
    }
}
