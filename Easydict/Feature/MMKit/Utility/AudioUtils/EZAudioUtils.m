//
//  EZAudioUtils.m
//  Easydict
//
//  Created by tisfeng on 2023/3/30.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZAudioUtils.h"
#import <CoreAudio/CoreAudio.h>

@implementation EZAudioUtils

/// Get system volume, [0, 100]
+ (float)getSystemVolume {
    AudioDeviceID outputDeviceID = [self getDefaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return 0.0;
    }
    
    Float32 volume;
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    if(!AudioObjectHasProperty(outputDeviceID, &address)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    UInt32 dataSize = sizeof(Float32);
    OSStatus status = AudioObjectGetPropertyData(outputDeviceID, &address, 0, NULL, &dataSize, &volume);
    if (status) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    if (volume < 0.0 || volume > 1.0) {
        NSLog(@"Invalid volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    return volume * 100;
}

/// Set system volume, [0, 100]
+ (void)setSystemVolume:(float)volume {
    AudioDeviceID outputDeviceID = [self getDefaultOutputDeviceID];
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return;
    }
    
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    
    if(!AudioObjectHasProperty(outputDeviceID, &address)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return;
    }
    
    Float32 newVolume = volume / 100.0;
    OSStatus status = AudioObjectSetPropertyData(outputDeviceID, &address, 0, NULL, sizeof(newVolume), &newVolume);
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

+ (AudioDeviceID)getDefaultOutputDeviceID {
    AudioDeviceID outputDeviceID = kAudioObjectUnknown; //get output device
    
    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    UInt32 dataSize = sizeof(AudioDeviceID);
    OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &dataSize, &outputDeviceID);
    if (status != 0) {
        NSLog(@"Cannot find default output device!");
    }
    
    return outputDeviceID;
}

@end
