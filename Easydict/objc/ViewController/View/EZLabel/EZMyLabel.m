//
//  EZMyLabel.m
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZMyLabel.h"

@implementation EZMyLabel

+ (instancetype)wrappingLabelWithString:(NSString *)stringValue {
    EZMyLabel *label = [super wrappingLabelWithString:stringValue];
    
    NSFont *textFont = [NSFont systemFontOfSize:14];
    label.font = textFont;
    label.backgroundColor = NSColor.clearColor;
    label.alignment = NSTextAlignmentLeft;
    label.characterSpacing = 3.5;
    label.lineSpacing = 3;
    label.paragraphSpacing = 5;
    
    [label setLineSpacing:1];
    [label setAllowsEditingTextAttributes:NO];
    
    return label;
}

// 设置字符间距
- (void)setCharacterSpacing:(CGFloat)characterSpacing {
    _characterSpacing = characterSpacing;

    // 获取当前的 NSMutableAttributedString
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedStringValue];

    // 修改字符间距
    [attributedString addAttribute:NSKernAttributeName value:@(_characterSpacing) range:NSMakeRange(0, attributedString.length)];

    // 重新设置属性字符串
    self.attributedStringValue = attributedString;
}

// 设置行间距
- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;

    // 获取当前的 NSMutableAttributedString
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedStringValue];

    // 获取当前的 NSMutableParagraphStyle
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = _lineSpacing;

    // 修改行间距
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];

    [self setAllowsEditingTextAttributes:YES];

    // 重新设置属性字符串
    self.attributedStringValue = attributedString;
    
    
//    NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
//    [textParagraph setLineSpacing:10.0];
//
//    NSDictionary *attrDic = [NSDictionary dictionaryWithObjectsAndKeys:textParagraph, NSParagraphStyleAttributeName, nil];
//    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:title attributes:attrDic];
//    [self setAllowsEditingTextAttributes:YES];
//    [self setAttributedStringValue:attrString];
}

// set paragraph spacing
- (void)setParagraphSpacing:(CGFloat)paragraphSpacing {
    _paragraphSpacing = paragraphSpacing;

    // 获取当前的 NSMutableAttributedString
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedStringValue];

    // 获取当前的 NSMutableParagraphStyle
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacing = _paragraphSpacing;

    // 修改行间距
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];

    // 重新设置属性字符串
    self.attributedStringValue = attributedString;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Drawing code here.
}

@end
