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
#import "EZTextWordUtils.h"

@interface EZAudioPlayer () <NSSpeechSynthesizerDelegate>

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) NSSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, assign) EZTTSServiceType defaultTTSServiceType;
@property (nonatomic, strong) EZQueryService *defaultTTSService;

@property (nonatomic, assign) EZServiceType serviceType;

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

- (EZTTSServiceType)defaultTTSServiceType {
    EZTTSServiceType ttsServiceType = [[NSUserDefaults mm_readString:EZDefaultTTSServiceKey defaultValue:@"0"] integerValue];
    return ttsServiceType;
}

- (EZQueryService *)defaultTTSService {
    if (!_defaultTTSService) {
        switch (self.defaultTTSServiceType) {
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

- (void)playWordPhonetic:(EZWordPhonetic *)wordPhonetic serviceType:(nullable EZServiceType)serviceType {
    [self playTextAudio:wordPhonetic.word
               language:wordPhonetic.language
                 accent:wordPhonetic.accent
               audioURL:wordPhonetic.speakURL
            serviceType:serviceType];
}

// TODO: need to optimize
- (void)playTextAudio:(NSString *)text textLanguage:(EZLanguage)language {
    [self playTextAudio:text
               language:language
                 accent:nil
               audioURL:nil
            serviceType:nil];
}

/// Play text audio.
- (void)playTextAudio:(NSString *)text
             language:(EZLanguage)language
               accent:(nullable NSString *)accent
             audioURL:(nullable NSString *)audioURL
          serviceType:(nullable EZServiceType)serviceType {
    if (!text.length) {
        NSLog(@"play text is empty");
        return;
    }
    
    self.playing = YES;
    if (!serviceType) {
        serviceType = self.service.serviceType;
    }
    self.serviceType = serviceType;
    
    BOOL isEnglishWord = [language isEqualToString:EZLanguageEnglish] && ([EZTextWordUtils isEnglishWord:text]);
    self.enableDownload = isEnglishWord;
    
    // 1. if has audio url, play audio url directly.
    if (audioURL.length) {
        [self playAudioURL:audioURL
                      text:text
                  language:language
                    accent:accent
               serviceType:serviceType];
        return;
    }
    
    // 2. if service type is Apple, use system speech.
    if (serviceType == EZServiceTypeApple) {
        [self playSystemTextAudio:text language:language];
        return;
    }
    
    // 3. get service text audio URL, and play.
    [self.service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
        EZAudioPlayer *audioPlayer = self.service.audioPlayer;
        if (!error && url.length) {
            [audioPlayer playTextAudio:text
                              language:language
                                accent:nil
                              audioURL:url
                           serviceType:nil];
        } else {
            NSLog(@"get audio url error: %@", error);
            
            // e.g. if Baidu get audio url failed, try to use default Google tts.
            if (![audioPlayer.service.class isEqual:audioPlayer.defaultTTSService.class]) {
                [audioPlayer.defaultTTSService.audioPlayer playTextAudio:text
                                                                language:language
                                                                  accent:accent
                                                                audioURL:audioURL
                                                             serviceType:serviceType];
            } else {
                [self playSystemTextAudio:text language:language];
            }
        }
    }];
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

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text language:(EZLanguage)language {
    NSSpeechSynthesizer *synthesizer = [self.appleService playTextAudio:text fromLanguage:language];
    synthesizer.delegate = self;
    self.synthesizer = synthesizer;
    self.playing = YES;
}

/// Play audio URL.
- (void)playAudioURL:(NSString *)audioURL
                text:(NSString *)text
            language:(EZLanguage)language
              accent:(nullable NSString *)accent
         serviceType:(EZServiceType)serviceType {
    if (audioURL.length == 0) {
        NSLog(@"play audio url is empty");
        return;
    }
    
    NSLog(@"play audio url: %@", audioURL);
    [self.player pause];
    
    NSString *filePath = [self getWordAudioFilePath:text
                                           language:language
                                             accent:accent
                                        serviceType:serviceType];
    // if audio file exist, play it.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self playLocalAudioFile:filePath];
        return;
    }
    
    // Since some of Youdao's audio cannot be played directly, it needs to be downloaded first, such as 'set'.
    BOOL download = self.enableDownload;
    
    if (download) {
        NSURL *URL = [NSURL URLWithString:audioURL];
        [self downloadWordAudio:text
                       audioURL:URL
                       autoPlay:YES
                       language:language
                         accent:accent
                    serviceType:serviceType];
    } else {
        [self playRemoteAudio:audioURL];
    }
}

/// Download word audio file.
- (void)downloadWordAudio:(NSString *)word
                 audioURL:(NSURL *)url
                 autoPlay:(BOOL)autoPlay
                 language:(EZLanguage)language
                   accent:(nullable NSString *)accent
              serviceType:(EZServiceType)serviceType {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *filePath = [self getWordAudioFilePath:word
                                               language:language
                                                 accent:accent
                                            serviceType:serviceType];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        if (autoPlay) {
            [self playLocalAudioFile:filePath.path];
        }
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
                          language:(EZLanguage)language
                            accent:(nullable NSString *)accent
                       serviceType:(EZServiceType)serviceType {
    NSString *audioDirectory = [self getAudioDirectory];
    
    // Avoid special characters in file name.
    word = [word md5];
    NSString *textLanguage = language;
    if ([language isEqualToString:EZLanguageEnglish] && !accent) {
        accent = @"us";
    }
    
    if (accent.length) {
        textLanguage = [textLanguage stringByAppendingFormat:@"-%@", accent];
    }
    
    NSString *audioFileName = [NSString stringWithFormat:@"%@_%@_%@", serviceType, textLanguage, word];
    
    /**
     TODO: maybe we should check the downloaded audio file type, some of them are not mp3, though the suggested extension is mp3, also can be played, but the file will 10x larger than m4a if we save it as mp3.
     
     e.g. 'set' from Youdao.
     */
    
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
