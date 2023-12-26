#import "MASShortcutMonitor.h"
#import "MASHotKey.h"

@interface MASShortcutMonitor ()
@property(assign) EventHandlerRef eventHandlerRef;
@property(strong) NSMutableDictionary *hotKeys;
@end

static OSStatus MASCarbonEventCallback(EventHandlerCallRef, EventRef, void*);
static NSUInteger MAShortcutDoubleModifierCode = 100000;
@implementation MASShortcutMonitor

#pragma mark Initialization

- (instancetype) init
{
    self = [super init];
    [self setHotKeys:[NSMutableDictionary dictionary]];
    EventTypeSpec hotKeyPressedSpec = { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed };
    OSStatus status = InstallEventHandler(GetEventDispatcherTarget(), MASCarbonEventCallback,
        1, &hotKeyPressedSpec, (__bridge void*)self, &_eventHandlerRef);
    if (status != noErr) {
        return nil;
    }
    
    [self addModifierDoubleClickListener];
    return self;
}

- (void) dealloc
{
    if (_eventHandlerRef) {
        RemoveEventHandler(_eventHandlerRef);
        _eventHandlerRef = NULL;
    }
}

+ (instancetype) sharedMonitor
{
    static dispatch_once_t once;
    static MASShortcutMonitor *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark Registration

- (BOOL) registerShortcut: (MASShortcut*) shortcut withAction: (dispatch_block_t) action
{
    MASHotKey *hotKey = [MASHotKey registeredHotKeyWithShortcut:shortcut];
    if (hotKey) {
        [hotKey setAction:action];
        [_hotKeys setObject:hotKey forKey:shortcut];
        return YES;
    } else {
        return NO;
    }
}

- (void) unregisterShortcut: (MASShortcut*) shortcut
{
    if (shortcut) {
        [_hotKeys removeObjectForKey:shortcut];
    }
}

- (void) unregisterAllShortcuts
{
    [_hotKeys removeAllObjects];
}

- (BOOL) isShortcutRegistered: (MASShortcut*) shortcut
{
    return !![_hotKeys objectForKey:shortcut];
}

- (void)addModifierDoubleClickListener {
    __block NSUInteger preFlag = -1;
    __weak typeof(self) weakSelf = self;
    // event Monitor
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent * _Nullable(NSEvent * event) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
        if (flags == NSEventModifierFlagCommand ||
            flags == NSEventModifierFlagOption  ||
            flags == NSEventModifierFlagShift   ||
            flags == NSEventModifierFlagControl) {
            if (preFlag != -1 && flags == preFlag) {
                NSUInteger modifierFlag = MASPickCocoaModifiers(flags);
//                NSString *eventKey = [strongSelf modifierFlagsString:modifierFlag];
                [strongSelf doubleClickHandleEventWithModifier:modifierFlag];
                preFlag = -1;
            } else {
                preFlag = flags;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    preFlag = -1;
                });
            }
        }
        return event;
    }];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent *event) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
        if (flags == NSEventModifierFlagCommand ||
            flags == NSEventModifierFlagOption  ||
            flags == NSEventModifierFlagShift   ||
            flags == NSEventModifierFlagControl) {
            if (preFlag != -1 && flags == preFlag) {
                NSUInteger modifierFlag = MASPickCocoaModifiers(flags);
//                NSString *eventKey = [strongSelf modifierFlagsString:modifierFlag];
                [strongSelf doubleClickHandleEventWithModifier:modifierFlag];
                preFlag = -1;
                
            } else {
                preFlag = flags;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    preFlag = -1;
                });
            }
        }
    }];
    
}

#pragma mark Event Handling
- (void)doubleClickHandleEventWithModifier:(NSUInteger)modifierFlag {
    __block BOOL flag = NO;
    [_hotKeys enumerateKeysAndObjectsUsingBlock:^(MASShortcut *shortcut, MASHotKey *hotKey, BOOL *stop) {
        if (shortcut.modifierFlags == modifierFlag && shortcut.keyCode == MAShortcutDoubleModifierCode)  {
            flag = YES;
            *stop = YES;
        } else if (shortcut.modifierFlags == modifierFlag && shortcut.keyCode == MAShortcutDoubleModifierCode) {
            flag = YES;
            *stop = YES;
        } else if (shortcut.modifierFlags == modifierFlag && shortcut.keyCode == MAShortcutDoubleModifierCode) {
            flag = YES;
            *stop = YES;
        } else if (shortcut.modifierFlags == modifierFlag && shortcut.keyCode == MAShortcutDoubleModifierCode) {
            flag = YES;
            *stop = YES;
        }
        if (flag && [hotKey action]) {
            dispatch_async(dispatch_get_main_queue(), [hotKey action]);
        }
    }];
}

- (NSString *)modifierFlagsString:(NSUInteger)modifierFlags {
    unichar chars[4];
    NSUInteger count = 0;
    // These are in the same order as the menu manager shows them
    if (modifierFlags & NSEventModifierFlagControl) chars[count++] = kControlUnicode;
    if (modifierFlags & NSEventModifierFlagOption) chars[count++] = kOptionUnicode;
    if (modifierFlags & NSEventModifierFlagShift) chars[count++] = kShiftUnicode;
    if (modifierFlags & NSEventModifierFlagCommand) chars[count++] = kCommandUnicode;
    return (count ? [NSString stringWithCharacters:chars length:count] : @"");
}

- (void) handleEvent: (EventRef) event {
    if (GetEventClass(event) != kEventClassKeyboard) {
        return;
    }

    EventHotKeyID hotKeyID;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID);
    if (status != noErr || hotKeyID.signature != MASHotKeySignature) {
        return;
    }

    [_hotKeys enumerateKeysAndObjectsUsingBlock:^(MASShortcut *shortcut, MASHotKey *hotKey, BOOL *stop) {
        if (hotKeyID.id == [hotKey carbonID]) {
            if ([hotKey action]) {
                dispatch_async(dispatch_get_main_queue(), [hotKey action]);
            }
            *stop = YES;
        }
    }];
}

@end

static OSStatus MASCarbonEventCallback(EventHandlerCallRef _, EventRef event, void *context)
{
    MASShortcutMonitor *dispatcher = (__bridge id)context;
    [dispatcher handleEvent:event];
    return noErr;
}
