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
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *text = @"si Il y a quatre-vingt-sept ans, nos pères ont donné naissance sur ce continent à une nouvelle nation, conçue dans la Liberté et vouée à la proposition selon laquelle tous les hommes sont créés égaux.\nMaintenant, nous sommes engagés dans une grande guerre civile, testant si cette nation, ou toute nation ainsi conçue et ainsi dévouée peut durer longtemps. Nous nous trouvons sur un grand champ de bataille de cette guerre. Nous sommes venus consacrer une partie de ce champ, comme lieu de repos final pour ceux qui ont donné leur vie ici pour que cette nation puisse vivre. Il est tout à fait approprié et approprié que nous fassions cela.\nMais, dans un sens plus large, nous ne pouvons pas consacrer – nous ne pouvons pas consacrer – nous ne pouvons pas sanctifier – ce terrain. Les hommes courageux, vivants et morts, qui ont lutté ici, l'ont consacré, bien au-dessus de notre pauvre pouvoir d'ajouter ou de retrancher. Le monde ne remarquera guère et ne se souviendra pas longtemps de ce que nous disons ici, mais il ne pourra jamais oublier ce qu’ils ont fait ici. C'est plutôt à nous, les vivants, de nous consacrer ici à l'œuvre inachevée que ceux qui ont combattu ici ont si noblement fait avancer jusqu'ici. C'est plutôt pour nous d'être ici consacrés à la grande tâche qui nous reste à accomplir – que de ces morts honorés nous tirions un dévouement accru à cette cause pour laquelle ils ont donné la dernière pleine mesure de dévouement – que nous sommes ici résolument résolus à ce que ces morts ne soient pas sont morts en vain – pour que cette nation, sous Dieu, connaisse une nouvelle naissance de liberté – et que le gouvernement du peuple, par le peuple, pour le peuple, ne périsse pas de la terre.";
    
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@",.\n "];
    NSArray *words = [text componentsSeparatedByCharactersInSet:separatorSet];
    
    for (NSString *word in words) {
        if (!word.length) {
            continue;;
        }
        
        EZLanguage language = [self.appleService detectText:word];
        if ([language isEqualToString:EZLanguageEnglish]) {
            if (![word isSpelledCorrectly]) {
                NSLog(@"misspelled word: %@", word);
            }
        } else {
            NSLog(@"Not English: %@ (%@)", word, language);
        }
    }
}



- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
