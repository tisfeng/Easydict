//
//  EZAudioUtils.m
//  Easydict
//
//  Created by tisfeng on 2023/3/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAudioUtils.h"
#import <CoreAudio/CoreAudio.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioServices.h>
#include <dlfcn.h>

@interface NSObject ()

- (void)setAccessibilityPreferenceAsMobile:(CFStringRef)key value:(CFBooleanRef)value notification:(CFStringRef)notification;

@end

@implementation EZAudioUtils

/// Get system volume, [0, 100]
+ (float)getSystemVolume {
    AudioDeviceID outputDeviceID = [self getDefaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        MMLogWarn(@"Unknown device");
        return 0.0;
    }
    
    Float32 volume;
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMain};
    
    if (!AudioObjectHasProperty(outputDeviceID, &address)) {
        MMLogWarn(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    UInt32 dataSize = sizeof(Float32);
    OSStatus status = AudioObjectGetPropertyData(outputDeviceID, &address, 0, NULL, &dataSize, &volume);
    if (status) {
        MMLogWarn(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    if (volume < 0.0 || volume > 1.0) {
        MMLogWarn(@"Invalid volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    float currentVolume = volume * 100;
//    MMLogError(@"--> getSystemVolume: %1.f", currentVolume);
    
    return currentVolume;
}

/// Set system volume, [0, 100]
+ (void)setSystemVolume:(float)volume {
//    MMLogError(@"--> setSystemVolume: %1.f", volume);
    
    AudioDeviceID outputDeviceID = [self getDefaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        MMLogWarn(@"Unknown device");
        return;
    }
    
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMain};
    
    if (!AudioObjectHasProperty(outputDeviceID, &address)) {
        MMLogWarn(@"No volume returned for device 0x%0x", outputDeviceID);
        return;
    }
    
    Float32 newVolume = volume / 100.0;
    OSStatus status = AudioObjectSetPropertyData(outputDeviceID, &address, 0, NULL, sizeof(newVolume), &newVolume);
    if (status) {
        MMLogWarn(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

+ (AudioDeviceID)getDefaultOutputDeviceID {
    AudioDeviceID outputDeviceID = kAudioObjectUnknown; // get output device
    
    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain};
    
    UInt32 dataSize = sizeof(AudioDeviceID);
    OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &dataSize, &outputDeviceID);
    if (status != 0) {
        MMLogWarn(@"Cannot find default output device!");
    }
    
    return outputDeviceID;
}


/// Get playing song info, Ref: https://stackoverflow.com/questions/61003379/how-to-get-currently-playing-song-on-mac-swift
+ (void)getPlayingSongInfo {
    CFBundleRef mediaRemoteBundle = mediaRemoteBundle = CFBundleCreate(NULL, (__bridge CFURLRef)[NSURL URLWithString:@"/System/Library/PrivateFrameworks/MediaRemote.framework"]);

    // Get a C function pointer for MRMediaRemoteGetNowPlayingInfo
    void *mrMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(mediaRemoteBundle, CFSTR("MRMediaRemoteGetNowPlayingInfo"));
    if (!mrMediaRemoteGetNowPlayingInfoPointer) {
        MMLogWarn(@"Failed to get MRMediaRemoteGetNowPlayingInfo function pointer");
        CFRelease(mediaRemoteBundle);
    }
    typedef void (*MRMediaRemoteGetNowPlayingInfoFunction)(dispatch_queue_t queue, void (^completionHandler)(NSDictionary *information));
    MRMediaRemoteGetNowPlayingInfoFunction mrMediaRemoteGetNowPlayingInfo = (MRMediaRemoteGetNowPlayingInfoFunction)mrMediaRemoteGetNowPlayingInfoPointer;
    
    // Get a C function pointer for MRNowPlayingClientGetBundleIdentifier
    void *mrNowPlayingClientGetBundleIdentifierPointer = CFBundleGetFunctionPointerForName(mediaRemoteBundle, CFSTR("MRNowPlayingClientGetBundleIdentifier"));
    if (!mrNowPlayingClientGetBundleIdentifierPointer) {
        MMLogWarn(@"Failed to get MRNowPlayingClientGetBundleIdentifier function pointer");
        CFRelease(mediaRemoteBundle);
    }
    
    // Get song info
    mrMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(NSDictionary *_Nonnull information) {
        MMLogInfo(@"information: %@", information);
        
        MMLogInfo(@"%@", information[@"kMRMediaRemoteNowPlayingInfoTitle"]);
        MMLogInfo(@"now date: %@", NSDate.now);
    });
    
    CFRelease(mediaRemoteBundle);
}


/// Use MediaRemote.framework to get MRMediaRemoteGetNowPlayingApplicationIsPlaying, Ref: https://github.com/PrivateFrameworks/MediaRemote/blob/5c10fd20fd6b1ef10d912f3bcb9037b1f61efb9e/Sources/PrivateMediaRemote/Functions.h
+ (void)isPlayingAudio:(void (^)(BOOL isPlaying))completion {
    CFBundleRef mediaRemoteBundle = mediaRemoteBundle = CFBundleCreate(NULL, (__bridge CFURLRef)[NSURL URLWithString:@"/System/Library/PrivateFrameworks/MediaRemote.framework"]);
    
    if (!mediaRemoteBundle) {
        MMLogInfo(@"Failed to load MediaRemote.framework");
    }
    
    // Get a C function pointer for MRMediaRemoteGetNowPlayingApplicationIsPlaying
    void *mrMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(mediaRemoteBundle, CFSTR("MRMediaRemoteGetNowPlayingApplicationIsPlaying"));
    if (!mrMediaRemoteGetNowPlayingApplicationIsPlayingPointer) {
        MMLogInfo(@"Failed to get MRMediaRemoteGetNowPlayingApplicationIsPlaying function pointer");
        CFRelease(mediaRemoteBundle);
    }
    
    typedef void (*MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)(dispatch_queue_t queue, void (^completionHandler)(BOOL isPlaying));
    
    MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction mrMediaRemoteGetNowPlayingApplicationIsPlaying = (MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)mrMediaRemoteGetNowPlayingApplicationIsPlayingPointer;
    
    mrMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(BOOL playing) {
        MMLogInfo(@"isPlaying: %d", playing);
        completion(playing);
    });
    
    CFRelease(mediaRemoteBundle);
}

// Note: AccessibilityUtilities is a private framework in iOS, it can not be linked during the build.
+ (nullable NSString *)setupAccessibilityOrReturnError {
    MMLogInfo(@"Enabling accessibility for automation on Simulator.");
    static NSString *path = @"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework/AccessibilityUtilities";
    
    char const *const localPath = [path fileSystemRepresentation];
    if (!localPath) {
        return @"localPath should not be nil";
    }
    
    void *handle = dlopen(localPath, RTLD_LOCAL);
    if (!handle) {
        return [NSString stringWithFormat:@"dlopen couldn't open AccessibilityUtilities at path %s", localPath];
    }
    
    Class AXBackBoardServerClass = NSClassFromString(@"AXBackBoardServer");
    if (!AXBackBoardServerClass) {
        return @"AXBackBoardServer class not found";
    }
    
    id server = [AXBackBoardServerClass valueForKey:@"server"];
    if (!server) {
        return @"server should not be nil";
    }
    
    [server setAccessibilityPreferenceAsMobile:(CFStringRef)@"ApplicationAccessibilityEnabled"
                                         value:kCFBooleanTrue
                                  notification:(CFStringRef)@"com.apple.accessibility.cache.app.ax"];
    
    [server setAccessibilityPreferenceAsMobile:(CFStringRef)@"AccessibilityEnabled"
                                         value:kCFBooleanTrue
                                  notification:(CFStringRef)@"com.apple.accessibility.cache.ax"];
    
    return nil;
}


@end
