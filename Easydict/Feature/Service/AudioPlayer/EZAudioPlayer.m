//
//  EZAudioPlayer.m
//  Easydict
//
//  Created by tisfeng on 2022/12/13.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAudioPlayer.h"
#import "EZAppleService.h"
#import <AVFoundation/AVFoundation.h>

@interface EZAudioPlayer ()

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation EZAudioPlayer

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark - Getter

- (EZAppleService *)appleService {
    if (!_appleService) {
        _appleService = [[EZAppleService alloc] init];
    }
    return _appleService;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

#pragma mark - Public Mehods

- (void)playSystemTextAudio:(NSString *)text {
    [self.appleService playTextAudio:text fromLanguage:EZLanguageAuto];
}

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text fromLanguage:(EZLanguage)from {
    [self.appleService playTextAudio:text fromLanguage:from];
}

/// Play text audio with designated service.
- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)language serive:(EZQueryService *)service {
    if (!text.length) {
        NSLog(@"playTextAudio is empty");
        return;
    }
    
    mm_weakify(self)
    [service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
        mm_strongify(self);
        if (!error) {
            [self playWord:text audioURL:url];
        } else {
            MMLogInfo(@"获取音频 URL 失败 %@", error);
        }
    }];
}

- (void)playWord:(NSString *)word audioURL:(nullable NSString *)urlString {
    MMLogInfo(@"播放音频 %@", urlString);
    
    [self.player pause];
    
    NSString *filePath = [self getWordAudioFilePath:word];
    // if audio file exist, play it
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self playLocalAudioFile:filePath];
        return;
    }
    
    if (!urlString.length) {
        if (!word.length) {
            return;
        }
        
        [self playSystemTextAudio:word];
        return;
    }
    
    // if audio file not exist, download it
    NSURL *URL = [NSURL URLWithString:urlString];
    [self downloadWordAudio:word audioURL:URL autoPlay:YES];
    return;
}

- (void)downloadWordAudio:(NSString *)word audioURL:(NSURL *)url {
    [self downloadWordAudio:word audioURL:url autoPlay:NO];
}

- (void)downloadWordAudio:(NSString *)word audioURL:(NSURL *)url autoPlay:(BOOL)autoPlay {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *filePath = [self getWordAudioFilePath:word];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        [self playLocalAudioFile:filePath.path];
    }];
    [downloadTask resume];
}

// Play local audio file
- (void)playLocalAudioFile:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"playLocalAudioFile not exist: %@", filePath);
        return;
    }
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:filePath]]];
    [self.player play];
}

// Get app cache directory
- (NSString *)getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// Get audio file directory, if not exist, create it.
- (NSString *)getAudioDirectory {
    NSString *cachesDirectory = [self getCacheDirectory];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *audioDirectory = [cachesDirectory stringByAppendingPathComponent:bundleID];
    audioDirectory = [audioDirectory stringByAppendingPathComponent:@"audio"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:audioDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:audioDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return audioDirectory;
}

// Get word audio file path
- (NSString *)getWordAudioFilePath:(NSString *)word {
    NSString *audioDirectory = [self getAudioDirectory];
    
    // m4a
    NSString *m4aFilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", word]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:m4aFilePath]) {
        return m4aFilePath;
    }
    
    // mp3
    NSString *mp3FilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", word]];
    return mp3FilePath;
}

- (BOOL)isAudioFilePlayable:(NSURL *)filePathURL {
    OSStatus status;
    AudioFileID audioFile;
    AudioFileTypeID fileType;
    
    NSLog(@"kAudioFileWAVEType: %d", kAudioFileWAVEType);
    
    status = AudioFileOpenURL((__bridge CFURLRef)filePathURL, kAudioFileReadPermission, 0, &audioFile);
    if (status == noErr) {
        UInt32 size = sizeof(fileType);
        status = AudioFileGetProperty(audioFile, kAudioFilePropertyFileFormat, &size, &fileType);
        if (status == noErr) {
            if (fileType == kAudioFileAAC_ADTSType) {
                NSLog(@"Audio file is of type: AAC ADTS");
            } else if (fileType == kAudioFileAIFFType) {
                NSLog(@"Audio file is of type: AIFF");
            } else if (fileType == kAudioFileCAFType) {
                NSLog(@"Audio file is of type: CAF");
            } else if (fileType == kAudioFileMP3Type) {
                NSLog(@"Audio file is of type: MP3");
            } else if (fileType == kAudioFileMPEG4Type) {
                NSLog(@"Audio file is of type: MP4");
            } else if (fileType == kAudioFileWAVEType) {
                NSLog(@"Audio file is of type: WAVE");
            } else {
                NSLog(@"Audio file is of an unknown type");
            }
        } else {
            NSLog(@"Error getting audio file property: %d", (int)status);
            return NO;
        }
    } else {
        NSLog(@"Error opening audio file type: %d", (int)status);
        return NO;
    }
    return YES;
}

@end
