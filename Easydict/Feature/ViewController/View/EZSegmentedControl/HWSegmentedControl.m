//
//  HWTopBlackView.m
//  Bus Servo Control
//
//  Created by xia luzheng on 2019/11/13.
//  Copyright © 2019 HiWonder. All rights reserved.
//

#import "HWSegmentedControl.h"

@interface HWSegmentedControl()

@property (nonatomic, strong) NSMutableArray  *paths;
@property (nonatomic, assign) float  maginLeftOne;//第一个坐标距离左边的位置

@end

@implementation HWSegmentedControl

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
    }
    return self;
}
- (void)initData
{
    self.titles = @[@"One",@"Two",@"Three"];
    self.maginLeftOne = 0;
    self.maginLeftTwo = 20;
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLanguage:) name:HWChangeLanguageNotification object:nil];
}

- (void)changeLanguage:(NSNotification*)noti
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor mm_colorWithHexString:@"#FFa500"].CGColor;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [NSColor mm_colorWithHexString:@"#FFa500"].CGColor;
    //    self.index = 3;
    // Drawing code here.
    [self reFresh];
}
- (NSMutableArray *)paths
{
    if (_paths == nil) {
        _paths = [NSMutableArray array];
    }
    return _paths;
}

- (CGSize)getTitleSize:(NSString *)title
{
    NSDictionary *dict = @{NSFontAttributeName:[NSFont systemFontOfSize:13]};
    NSSize size = [title boundingRectWithSize:NSMakeSize(MAXFLOAT, self.frame.size.height - 6) options:0 attributes:dict context:nil].size;
    return size;
}

- (void)reFresh
{
    [self.paths removeAllObjects];
    NSString *title = self.titles[0];
    //    NSDictionary *dict = @{NSFontAttributeName:[NSFont systemFontOfSize:13]};
    //    NSSize size = [title boundingRectWithSize:NSMakeSize(MAXFLOAT, kPointMake(36)) options:0 attributes:dict context:nil].size;
    //    NSLog(@"%f",13);
    NSRect rect = self.frame;
    
    CGFloat widthFirst = [self getTitleSize:title].width ;
    
    float lineWidth = 1;
    
    float point1_x = self.maginLeftOne;
    float point1_y = 0;
    CGPoint point1 = CGPointMake(point1_x, point1_y);
    
    float point2_x = self.maginLeftOne;
    float point2_y = self.frame.size.height + lineWidth / 2.0 ;
    CGPoint point2 = CGPointMake(point2_x, point2_y);
    
    float point3_x = point2_x + widthFirst + self.maginLeftTwo * 2;
    float point3_y = point2_y;
    CGPoint point3 = CGPointMake(point3_x, point3_y);
    
    float point4_x = point3_x ;
    float point4_y = point1_y;
    CGPoint point4 = CGPointMake(point4_x, point4_y);
    
    NSColor *textColorBlack = [NSColor mm_colorWithHexString:@"#FFa500"];
    NSColor *textColorWhite = [NSColor mm_colorWithHexString:@"#fdfefe"];
    NSColor *textColor = textColorBlack;
    for (int i = 0; i<self.titles.count; i++) {
        NSString *title = self.titles[i];
        NSSize size = [self getTitleSize:title];
        
        if (i == 0) {
            rect.size.width = size.width + self.maginLeftTwo * 2;
        }else{
            rect.size.width = rect.size.width + size.width + self.maginLeftTwo * 2;
        }
        
        //        self.frame = rect;
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            //            make.top.equalTo(self.superview).with.offset(40);
            //                         make.centerX.equalTo(self.superview);
            make.width.mas_equalTo(@(rect.size.width));
            //                         make.height.mas_equalTo(@(26));
        }];
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        path.lineWidth = lineWidth;
        
        if (i != 0) {
            point1 = point4;
            point2 = CGPointMake(point3.x, point3.y - lineWidth / 2.0);
            if (self.index != 0 && i == self.index) {
                point2_y = point2.y + lineWidth ;
                point2 = CGPointMake(point2.x, point2_y);
            }
            point3_x = point3_x + size.width  + self.maginLeftTwo * 2;
            point3_y = point3_y ;
            point3 = CGPointMake(point3_x, point3_y);
            
            point4_x = point4_x + size.width + self.maginLeftTwo * 2;
            if (self.titles.count == 2) {
                point3_x = point3_x + 1;
                point3 = CGPointMake(point3_x, point3_y);
                point4_x = point4_x + 1;
            }
            point4_y = point4_y;
            point4 = CGPointMake(point4_x, point4_y);
        }
        
        [path moveToPoint:point1];
        [path lineToPoint:point2];
        [path lineToPoint:point3];
        [path lineToPoint:point4];
        [path lineToPoint:point1];
        [[NSColor whiteColor]set];
        path.lineCapStyle = NSLineCapStyleRound;
        path.lineJoinStyle = NSLineJoinStyleRound;
        
        if (self.index != i) {
            [path fill];
            textColor = textColorBlack ;
        }else{
            [path stroke];
            textColor = textColorWhite;
        }
        NSDictionary *dicAtt = @{NSFontAttributeName:[NSFont systemFontOfSize:13],NSForegroundColorAttributeName:textColor};
        [title drawAtPoint:NSMakePoint(point2.x + self.maginLeftTwo , (self.frame.size.height - size.height) / 2.0) withAttributes:dicAtt];
        [self.paths addObject:path];
    }
}

- (void)mouseDown:(NSEvent *)event
{
    CGPoint eventLocation = [event locationInWindow];
    NSPoint point = [self convertPoint:eventLocation fromView:nil];
    [self.paths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSBezierPath *path = obj;
        if ([path containsPoint:point]) {
            NSLog(@"mouseDown  %ld",idx);
//            if (self.index != idx) {
//               
//            }
            
            self.index = idx;
            [self setNeedsDisplay:YES];
            if ([self.delegate respondsToSelector:@selector(selectTitleIndex:)]) {
                [self.delegate selectTitleIndex:self.index];
            }
        }
    }];
}

@end
