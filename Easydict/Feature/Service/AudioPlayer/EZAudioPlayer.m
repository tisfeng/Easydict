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
#import "EZQueryService.h"
#import "EZEnumTypes.h"
#import "EZBaiduTranslate.h"
#import "EZGoogleTranslate.h"

@interface EZAudioPlayer () <NSSpeechSynthesizerDelegate>

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) NSSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, assign) EZTTSServiceType ttsServiceType;

@end

@implementation EZAudioPlayer

@synthesize playing = _playing;


- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPlaying:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPlaying:)
                                                 name:AVPlayerItemNewErrorLogEntryNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPlaying:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:nil];
}

// ???: Why is this method called multiple times?
- (void)didFinishPlaying:(NSNotification *)notification {
    AVPlayerItem *playerItem = notification.object;
    if (self.player.currentItem == playerItem) {
        self.playing = NO;
    }
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

- (void)setPlaying:(BOOL)playing {
    _playing = playing;

    if (self.playingBlock) {
        self.playingBlock(playing);
    }
}

- (EZTTSServiceType)ttsServiceType {
    EZTTSServiceType ttsServiceType = [[NSUserDefaults mm_readString:EZDefaultTTSServiceKey defaultValue:@"0"] integerValue];
    return ttsServiceType;
}

- (EZQueryService *)defaultTTSService {
    if (!_defaultTTSService) {
        switch (self.ttsServiceType) {
            case EZTTSServiceTypeBaidu: {
                _defaultTTSService = [[EZBaiduTranslate alloc] init];
                break;
            }
            case EZTTSServiceTypeGoogle: {
                _defaultTTSService = [[EZGoogleTranslate alloc] init];
                break;
            }
            default: {
                _defaultTTSService = self.appleService;
                break;
            }
        }
    }
    _defaultTTSService.audioPlayer = self;

    return _defaultTTSService;
}

- (EZQueryService *)service {
    if (!_service) {
        _service = self.defaultTTSService;
    }
    return _service;
}

#pragma mark - Public Mehods

- (void)playTextAudio:(NSString *)text textLanguage:(EZLanguage)language {
    if (self.service && self.service.serviceType != EZServiceTypeApple) {
        [self playTextAudio:text audioURL:nil textLanguage:language];
    } else {
        [self playSystemTextAudio:text textLanguage:language];
    }
}

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text textLanguage:(EZLanguage)language {
    NSSpeechSynthesizer *synthesizer = [self.appleService playTextAudio:text fromLanguage:language];
    synthesizer.delegate = self;
    self.synthesizer = synthesizer;
    self.playing = YES;
}

/// Play text URL audio.
- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         textLanguage:(EZLanguage)language {
    if (!text.length) {
        NSLog(@"play text is empty");
        return;
    }

    self.playing = YES;

    if (audioURL.length) {
        BOOL useCache = NO;
        BOOL usPhonetic = YES;
        [self getUseCache:&useCache usPhonetic:&usPhonetic audioURL:audioURL];
        [self playTextAudio:text
                   audioURL:audioURL
               fromLanguage:language
                   useCache:useCache
                 usPhonetic:usPhonetic
                serviceType:self.service.serviceType];
        return;
    }

    if (self.service) {
        [self.service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
            if (!error && url.length) {
                [self.service.audioPlayer playTextAudio:text audioURL:url textLanguage:language];
            } else {
                NSLog(@"get audio url error: %@", error);
                [self playTextAudio:text textLanguage:language];
            }
        }];

        return;
    }
    
    [self playTextAudio:text textLanguage:language];
}

- (void)stop {
    NSLog(@"stop play");

    // !!!: This method won't post play end notification.
    [self.player pause];

    // It wiil call delegate.
    [self.synthesizer stopSpeaking];

    self.playing = NO;
}


#pragma mark - NSSpeechSynthesizerDelegate

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
    self.playing = NO;
}


#pragma mark -

/// Get &useCache and &usPhonetic from service.
- (void)getUseCache:(BOOL *)useCache
         usPhonetic:(BOOL *)usPhonetic
           audioURL:(NSString *)audioURL {
    if (self.service.serviceType == EZServiceTypeYoudao) {
        *useCache = YES;

        // uk https://dict.youdao.com/dictvoice?audio=class&type=1

        // get type from audioURL
        NSString *type = [audioURL componentsSeparatedByString:@"&type="].lastObject;
        // if type is 1, use ukPhonetic
        if ([type isEqualToString:@"1"]) {
            *usPhonetic = NO;
        }
    }
}


- (void)playTextAudio:(NSString *)text
             audioURL:(nullable NSString *)audioURL
         fromLanguage:(EZLanguage)language
             useCache:(BOOL)useCache
           usPhonetic:(BOOL)usPhonetic
          serviceType:(EZServiceType)serviceType {
    NSLog(@"play audio url: %@", audioURL);

    [self.player pause];

    NSString *filePath = [self getWordAudioFilePath:text usPhonetic:usPhonetic serviceType:serviceType];
    // if audio file exist, play it
    if (useCache && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self playLocalAudioFile:filePath];
        return;
    }

    if (!audioURL.length) {
        if (!text.length) {
            return;
        }

        [self playTextAudio:text textLanguage:language];
        return;
    }

    // Since some of Youdao's audio cannot be played directly, it needs to be downloaded first, such as 'set'.
    
    BOOL download = self.enableDownload;
    
    if (download) {
        NSURL *URL = [NSURL URLWithString:audioURL];
        [self downloadWordAudio:text audioURL:URL autoPlay:YES usPhonetic:usPhonetic serviceType:serviceType];
    } else {
        [self playRemoteAudio:audioURL];
    }
}

- (void)downloadWordAudio:(NSString *)word
                 audioURL:(NSURL *)url
                 autoPlay:(BOOL)autoPlay
               usPhonetic:(BOOL)usPhonetic
              serviceType:(EZServiceType)serviceType {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *filePath = [self getWordAudioFilePath:word usPhonetic:usPhonetic serviceType:serviceType];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        [self playLocalAudioFile:filePath.path];
    }];
    [downloadTask resume];
}

/// Play local audio file
- (void)playLocalAudioFile:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"playLocalAudioFile not exist: %@", filePath);
        return;
    }

    NSURL *url = [NSURL fileURLWithPath:filePath];
    [self playAudioWithURL:url];
}

/// Play audio with remote url string.
- (void)playRemoteAudio:(NSString *)urlString {
    if (!urlString.length) {
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    [self playAudioWithURL:url];
}

/// Play audio with NSURL
- (void)playAudioWithURL:(NSURL *)url {
    [self.player pause];
        
    AVAsset *asset = [AVAsset assetWithURL:url];
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        NSLog(@"Invalid asset.");
        return;
    }

    if ([asset isPlayable]) {
        [self.player pause];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [self.player play];
    } else {
        // TODO: maybe need to show a failure toast.
        NSLog(@"Invalid file or file does not exist");
        self.playing = NO;
    }
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
- (NSString *)getWordAudioFilePath:(NSString *)word
                        usPhonetic:(BOOL)usPhonetic
                       serviceType:(EZServiceType)serviceType {
    NSString *audioDirectory = [self getAudioDirectory];

    word = [word md5];
    NSString *audioFileName = [NSString stringWithFormat:@"%@_%@_%@", word, serviceType, usPhonetic ? @"us" : @"uk"];

    // m4a
    NSString *m4aFilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", audioFileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:m4aFilePath]) {
        return m4aFilePath;
    }

    // mp3
    NSString *mp3FilePath = [audioDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", audioFileName]];
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
