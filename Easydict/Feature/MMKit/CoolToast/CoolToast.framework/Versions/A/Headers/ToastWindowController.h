//
//  ToastWindowController.h
//  CoolToast
//
//  Created by Socoolby on 2019/6/28.
//  Copyright © 2019 Socoolby. All rights reserved.
//

#import <Cocoa/Cocoa.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_OPTIONS(NSUInteger,CTPosition){
    CTPositionMouse             =1<<15,
    CTPositionCenter            =1<<16,
    CTPositionLeft              =1<<17,
    CTPositionTop               =1<<18,
    CTPositionRight             =1<<19,
    CTPositionBottom            =1<<20,
    CTPositionOnMainWindow      =1<<21,
    CTPositionAllWindow         =1<<22,
} ;
typedef NS_OPTIONS(NSUInteger,CTAnimater){
    CTAnimaterFade                  =1,
    CTAnimaterScale                 =2,
    CTAnimaterTranslateFromLeft     =3,
    CTAnimaterTranslateFromTop      =4,
    CTAnimaterTranslateFromRight    =5,
    CTAnimaterTranslateFromBottom   =6,
    CTAnimaterNone                  =7,
};
@protocol ToastWindowDelegate <NSObject>
-(void)onCoolToastDismiss:(id)toastWindow;
-(void)onCoolToastClick:(id)toastWindow;
@end
@interface ToastWindowController : NSWindowController
@property (weak) IBOutlet NSTextFieldCell *messageLabel;
@property (weak) IBOutlet NSImageCell *iconImageCell;
@property (nonatomic) NSInteger maxWidth;
@property (nonatomic) NSInteger minWidth;
@property (nonatomic) int minHeight;
@property (nonatomic) NSInteger leftOffset;
@property (nonatomic) NSInteger topOffset;
@property (nonatomic) NSInteger rightOffset;
@property (nonatomic) NSInteger bottomOffset;
@property (nonatomic) NSInteger conerRadius;
@property (nonatomic) BOOL autoDismiss;
@property (nonatomic) NSUInteger autoDismissTimeInSecond;
@property (nonatomic) CTPosition toastPostion;
@property (nonatomic) CTAnimater animater;
@property (nonatomic) float animaterTimeSecond;
@property (nonatomic) BOOL hiddenIcon;
@property (nonatomic) int imageMarginLeft;
@property (nonatomic) NSImage *iconImage;

@property (nonatomic,strong) NSColor *backgroundColor;
@property (nonatomic,strong) NSColor *toastBackgroundColor;
@property (nonatomic,strong) NSColor *textColor;
@property (nonatomic,strong) NSFont *textFont;

@property (weak) IBOutlet NSView *containerView;

@property (nonatomic,strong) id<ToastWindowDelegate> delegate;

+(id)getToastWindow;
-(void)showCoolToast:(NSString*)message;
- (IBAction)onContainerDoubleClick:(id)sender;
@end

NS_ASSUME_NONNULL_END
