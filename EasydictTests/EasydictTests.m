//
//  EasydictTests.m
//  EasydictTests
//
//  Created by tisfeng on 2023/10/10.
//  Copyright © 2023 izual. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EZAppleService.h"
#import "NSString+EZUtils.h"
#import "NSString+EZHandleInputText.h"

@interface EasydictTests : XCTestCase

@property (nonatomic, strong) EZAppleService *appleService;

@end

@implementation EasydictTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.appleService = [[EZAppleService alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {

}

- (void)testSplitCode {
    XCTAssert([[@"ResultBaseModel" splitCodeText] isEqualToString:@"Result Base Model"]);
    XCTAssert([[@"getHTTP" splitCodeText] isEqualToString:@"get HTTP"]);
    XCTAssert([[@"getHTTPCode" splitCodeText] isEqualToString:@"get HTTP Code"]);
    
    XCTAssert([[@"anchored_draggable_state" splitCodeText] isEqualToString:@"anchored draggable state"]);
    XCTAssert([[@"anchored_Draggable_State" splitCodeText] isEqualToString:@"anchored Draggable State"]);
}

- (void)testRemoveQuotes {
    NSString *text = @"\"\"\"创造力就是让智慧尽情玩耍。——爱因斯坦\"\"\"";
    NSString *newText =  text.tryToRemoveQuotes;
    XCTAssert([newText isEqualToString:@"创造力就是让智慧尽情玩耍。——爱因斯坦"]);
}

- (void)testDetectLanguage {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    NSArray *englishWords = @[@"good", @"const", @"xml"];
    
    for (NSString *word in englishWords) {
        EZLanguage language = [self.appleService detectText:word];
        BOOL success = [language isEqualToString:EZLanguageEnglish];
        NSString *errorMessage = [NSString stringWithFormat:@"detect English word incorrectly: %@(%@)", word, language];
        NSAssert(success, errorMessage);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
