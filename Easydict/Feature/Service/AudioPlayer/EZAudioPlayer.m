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
#import "NSString+EZUtils.h"
#import "EZServiceTypes.h"
#import "EZConfiguration.h"
#import <sys/xattr.h>

static NSString *const kFileExtendedAttributes = @"NSFileExtendedAttributes";

// kMDItemWhereFroms
static NSString *const kItemWhereFroms = @"com.apple.metadata:kMDItemWhereFroms";

@interface EZAudioPlayer () <NSSpeechSynthesizerDelegate>

@property (nonatomic, strong) EZAppleService *appleService;
@property (nonatomic, strong) NSSpeechSynthesizer *synthesizer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, strong) EZQueryService *defaultTTSService;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) EZLanguage language;
@property (nonatomic, copy) NSString *audioURL;
@property (nonatomic, copy, nullable) NSString *accent;
@property (nonatomic, copy, nonnull) EZServiceType serviceType;

@property (nonatomic, copy, nonnull) EZServiceType currentServiceType;

@end

@implementation EZAudioPlayer

@synthesize isPlaying = _isPlaying;

+ (instancetype)shared {
    static EZAudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EZAudioPlayer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.useSystemTTSWhenPlayFailed = YES;
    
    // KVO timeControlStatus is not a good choice
    
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
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPlaying:)
                                                 name:AVPlayerItemNewErrorLogEntryNotification
                                               object:nil];
}

- (void)didFinishPlaying:(NSNotification *)notification {
    AVPlayerItem *playerItem = notification.object;
    if (self.player.currentItem == playerItem) {
        self.isPlaying = NO;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)setIsPlaying:(BOOL)playing {
    _isPlaying = playing;
    
    if (self.playingBlock) {
        self.playingBlock(playing);
    }
}

// Note that user may change it when using, so we need to read it every time.
- (EZQueryService *)defaultTTSService {
    EZServiceType defaultTTSServiceType = EZConfiguration.shared.defaultTTSServiceType;
    if (![_defaultTTSService.serviceType isEqualToString:defaultTTSServiceType]) {
        EZQueryService *defaultTTSService = [EZServiceTypes.shared serviceWithType:defaultTTSServiceType];
        _defaultTTSService = defaultTTSService;
        _defaultTTSService.audioPlayer = self;
        
        if (defaultTTSServiceType == EZServiceTypeApple) {
            self.appleService = (EZAppleService *)defaultTTSService;
        }
    }
    return _defaultTTSService;
}

- (EZQueryService *)service {
    if (!_service) {
        _service = self.defaultTTSService;
    }
    return _service;
}


#pragma mark - Public Mehods

- (void)playWordPhonetic:(EZWordPhonetic *)wordPhonetic designatedService:(nullable EZQueryService *)designatedService  {
    [self playTextAudio:wordPhonetic.word
               language:wordPhonetic.language
                 accent:wordPhonetic.accent
               audioURL:wordPhonetic.speakURL
      designatedService:designatedService
               forceURL:YES];
}

// TODO: need to optimize
- (void)playTextAudio:(NSString *)text textLanguage:(EZLanguage)language {
    [self playTextAudio:text
               language:language
                 accent:nil
               audioURL:nil
      designatedService:nil];
}

/// Play text audio.
- (void)playTextAudio:(NSString *)text
             language:(EZLanguage)language
               accent:(nullable NSString *)accent
             audioURL:(nullable NSString *)audioURL
    designatedService:(nullable EZQueryService *)designatedService {
    [self playTextAudio:text
               language:language
                 accent:accent
               audioURL:audioURL
      designatedService:designatedService
               forceURL:NO];
}

/// Play text audio, forceURL
- (void)playTextAudio:(NSString *)text
             language:(EZLanguage)language
               accent:(nullable NSString *)accent
             audioURL:(nullable NSString *)audioURL
    designatedService:(nullable EZQueryService *)designatedService
             forceURL:(BOOL)forceURL {
    if (!text.length) {
        NSLog(@"play text is empty");
        return;
    }
    
    self.isPlaying = YES;
    self.serviceType = designatedService.serviceType ?: self.service.serviceType;
    
    self.text = text;
    self.language = language;
    self.audioURL = audioURL;
    self.accent = accent;
    
    BOOL isEnglishWord = [text isEnglishWordWithLanguage:language];
    self.enableDownload = isEnglishWord;
    
    // 1. if has audio url, play audio url directly.
    if (audioURL.length) {
        [self playAudioURL:audioURL
                      text:text
                  language:language
                    accent:accent
               serviceType:self.serviceType
                  forceURL:forceURL];
        return;
    }
    
    // 2. if service type is Apple, use system speech.
    if (self.serviceType == EZServiceTypeApple) {
        [self playSystemTextAudio:text language:language];
        return;
    }
    
    EZQueryService *service = designatedService ?: self.service;
    
    // 3. get service text audio URL, and play.
    [service textToAudio:text fromLanguage:language completion:^(NSString *_Nullable url, NSError *_Nullable error) {
        self.currentServiceType = service.serviceType;
        
        if (!error && url.length) {
            [self playTextAudio:text
                       language:language
                         accent:nil
                       audioURL:url
              designatedService:service];
        } else {
            NSLog(@"get audio url error: %@", error);
            
            // e.g. if service get audio url failed, try to use default tts, such as Google.
            [self playFallbackTTSWithFailedServiceType:service.serviceType];
        }
    }];
}


- (void)stop {
//    NSLog(@"stop play");
    
    // !!!: This method won't post play end notification.
    [_player pause];
    
    // It wiil call delegate.
    [_synthesizer stopSpeaking];
    
    self.isPlaying = NO;
}


#pragma mark - NSSpeechSynthesizerDelegate

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
    self.isPlaying = NO;
}


#pragma mark -

/// Play system text audio.
- (void)playSystemTextAudio:(NSString *)text language:(EZLanguage)language {
    NSSpeechSynthesizer *synthesizer = [self.appleService playTextAudio:text textLanguage:language];
    synthesizer.delegate = self;
    self.synthesizer = synthesizer;
    self.isPlaying = YES;
}

/// Play audio URL.
- (void)playAudioURL:(NSString *)audioURLString
                text:(NSString *)text
            language:(EZLanguage)language
              accent:(nullable NSString *)accent
         serviceType:(EZServiceType)serviceType
            forceURL:(BOOL)forceURL {
    if (audioURLString.length == 0) {
        NSLog(@"play audio url is empty");
        return;
    }
    
    self.currentServiceType = serviceType;
    
    [self.player pause];
        
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isForcedURL = forceURL && audioURLString.length;
    
    // For English words, Youdao TTS is better than other services, so we try to play local Youdao audio first.
    BOOL isEnglishWord = [text isEnglishWordWithLanguage:language];

    if (!isForcedURL && isEnglishWord) {
        NSString *youdaoAudioFilePath = [self getWordAudioFilePath:text
                                                          language:language
                                                            accent:accent
                                                       serviceType:EZServiceTypeYoudao];
        
        if ([fileManager fileExistsAtPath:youdaoAudioFilePath]) {
            [self playLocalAudioFile:youdaoAudioFilePath];
            return;
        }
    }
    
    // If audio url is a local file url
    if ([fileManager fileExistsAtPath:audioURLString]) {
        [self playLocalAudioFile:audioURLString];
        return;
    }
    
    NSString *audioFilePath = [self getWordAudioFilePath:text
                                           language:language
                                             accent:accent
                                        serviceType:serviceType];
    
    // If audio file exist, play it.
    if ([fileManager fileExistsAtPath:audioFilePath]) {
        [self playLocalAudioFile:audioFilePath];
        return;
    }
    
    NSLog(@"play remote audio url: %@", audioURLString);

    // Since some of Youdao's audio cannot be played directly, it needs to be downloaded first, such as 'set'.
    BOOL download = self.enableDownload;
    
    if (download) {
        NSURL *URL = [NSURL URLWithString:audioURLString];
        [self downloadWordAudio:text
                       audioURL:URL
                       autoPlay:YES
                       language:language
                         accent:accent
                    serviceType:serviceType];
    } else {
        [self playRemoteAudio:audioURLString];
    }
}

/// Download word audio file.
- (void)downloadWordAudio:(NSString *)word
                 audioURL:(NSURL *)URL
                 autoPlay:(BOOL)autoPlay
                 language:(EZLanguage)language
                   accent:(nullable NSString *)accent
              serviceType:(EZServiceType)serviceType {
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *filePath = [self getWordAudioFilePath:word
                                               language:language
                                                 accent:accent
                                            serviceType:serviceType];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"Download file to: %@", filePath.path);
        if (autoPlay) {
            [self playLocalAudioFile:filePath.path];
        }
    }];
    [downloadTask resume];
}

- (void)testFileInfo:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/tisfeng/Downloads/reader-ios-master.zip"];
    NSArray *URLs = [self getDownloadSourcesForFilePath:fileURL.path];
    
    NSArray *urls = @[
        @"https://github.com/yuenov/reader-ios",
        @"https://codeload.github.com/yuenov/reader-ios/zip/refs/heads/master",
    ];

    [self setDownloadSourceForFilePath:filePath sourceURLs:urls];
    URLs = [self getDownloadSourcesForFilePath:filePath];
    NSLog(@"URLs: %@", URLs);

}

/// Play local audio file
- (void)playLocalAudioFile:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:filePath]) {
        self.isPlaying = NO;
        NSLog(@"playLocalAudioFile not exist: %@", filePath);
        return;
    }
    NSLog(@"play local audio file: %@", filePath);
    

    if ([self canPlayLocalAudioFileAtPath:filePath]) {
        NSURL *URL = [NSURL fileURLWithPath:filePath];
        [self playAudioURL:URL];
    } else {
        // If audio file extension is not correct, we need to try to correct it.
        NSString *newFilePath = [self tryCorrectAudioFileTypeWithPath:filePath];
        if (newFilePath) {
            if ([self canPlayLocalAudioFileAtPath:newFilePath]) {
                [self playAudioURL:[NSURL fileURLWithPath:newFilePath]];
                return;
            }
        }
        
        // If local audio file is broke, we need to remove it.
        [fileManager removeItemAtPath:filePath error:nil];
        
        [self playFallbackTTSWithFailedServiceType:self.currentServiceType];
    }
}

/// Check if can play local audio file.
- (BOOL)canPlayLocalAudioFileAtPath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    // Maybe the audio file is broken, we need to check it.
    NSError *error = nil;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];

    AVAsset *asset = [AVAsset assetWithURL:fileURL];

    if (!asset.readable || !asset.isPlayable) {
        // change go.mp3 to go.m4a will cause asset not readable
        NSLog(@"asset not readable or playable: %@", filePath);
        return NO;
    }
    
    BOOL success = [audioPlayer prepareToPlay];
    if (!success || error) {
        // If audio data is .wav, but save it as .mp3, it will not be ready to play.
        NSLog(@"prepareToPlay failed: %@, error: %@", filePath, [error localizedDescription]);
        return NO;
    }
    
    return YES;
}

/// Play audio with remote url string.
- (void)playRemoteAudio:(NSString *)urlString {
    if (!urlString.length) {
        return;
    }
    
    // TODO: maybe we need to pre-load audio url, then play when user click.
    
    NSURL *URL = [NSURL URLWithString:urlString];
    [self loadAudioURL:URL completion:^(AVAsset *_Nullable asset) {
        if (asset) {
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            [self playWithPlayerItem:playerItem];
        } else {
            [self playFallbackTTSWithFailedServiceType:self.currentServiceType];
        }
    }];
}


/// Play audio with NSURL
- (void)playAudioURL:(NSURL *)URL {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:URL];
    [self playWithPlayerItem:playerItem];
}

- (void)playWithPlayerItem:(AVPlayerItem *)playerItem {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [self.player play];
}

- (void)play {
    NSURL *URL = [NSURL fileURLWithPath:self.audioURL];
    [self playAudioURL:URL];
}

/// Play fallback TTS when service failed.
/// TODO: need to optimize.
- (void)playFallbackTTSWithFailedServiceType:(EZServiceType)failedServiceType {
    NSLog(@"play fallback TTS with failed service: %@", failedServiceType);
    
    EZAudioPlayer *audioPlayer = self.service.audioPlayer;
    if (![failedServiceType isEqualToString:audioPlayer.defaultTTSService.serviceType]) {
        EZAudioPlayer *defaultTTSAudioPlayer = audioPlayer.defaultTTSService.audioPlayer;
        [defaultTTSAudioPlayer playTextAudio:self.text
                                    language:self.language
                                      accent:self.accent
                                    audioURL:nil
                           designatedService:defaultTTSAudioPlayer.defaultTTSService];
    } else {
        if (self.useSystemTTSWhenPlayFailed) {
            [self playSystemTextAudio:self.text language:self.language];
        }
    }
}

- (void)loadAudioURL:(NSURL *)URL completion:(void (^)(AVAsset *_Nullable asset))completion {
    if ([URL isFileURL]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:URL.path]) {
            AVAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
            completion(asset);
        } else {
            completion(nil);
        }
        return;
    }
    
    // Check URL is valid
    if (!URL || !URL.scheme || !URL.host) {
        NSLog(@"audio url is invalid: %@", URL);
        completion(nil);
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    NSArray *resourceKeys = @[ @"playable" ];
    [asset loadValuesAsynchronouslyForKeys:resourceKeys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"playable" error:&error];
        
        BOOL isPlayable = NO;
        if (status == AVKeyValueStatusLoaded) {
            if (asset.isPlayable) {
                isPlayable = YES;
            }
        } else {
            NSLog(@"load playable failed: %@", [error localizedDescription]);
        }
        NSLog(@"audio url isPlayable: %d", isPlayable);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isPlayable) {
                completion(asset);
            } else {
                completion(nil);
            }
        });
    }];
}


#pragma mark -

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
    
    NSString *filePath = [self filePathWithFileName:audioFileName atDrectoryPath:audioDirectory];
    if (!filePath) {
        // May we use wav as ddefault audio format, since set.mp3 can not be played.
        // If is .wav file, it can not play, we will correct file type later.
        NSString *fileNameWithExtension = [NSString stringWithFormat:@"%@.mp3", audioFileName];
        filePath = [audioDirectory stringByAppendingPathComponent:fileNameWithExtension];
    }
    
    return filePath;
}

// Get file path with file name in directory
- (nullable NSString *)filePathWithFileName:(NSString *)fileName atDrectoryPath:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    
    for (NSString *file in enumerator) {
        NSString *name = [file stringByDeletingPathExtension];
        if ([name isEqualToString:fileName]) {
            return [directoryPath stringByAppendingPathComponent:file];
        }
    }
    
    return nil;
}


/// Get audio file type with file path.
- (NSString *)audioFileTypeWithPath:(NSString *)filePath {
    AudioFileTypeID fileTypeID = [self audioFileTypeIDWithPath:filePath];
    NSString *fileType = [self getFileTypeString:fileTypeID];
    return fileType;
}

- (AudioFileTypeID)audioFileTypeIDWithPath:(NSString *)filePath {
    NSURL *filePathURL = [NSURL fileURLWithPath:filePath];
    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfURL:filePathURL options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        NSLog(@"read audio file data error: %@", error);
    }
    
    return [self fileTypeWithData:fileData];
}

/// Get audio AudioFileTypeID with NSData
- (AudioFileTypeID)fileTypeWithData:(NSData *)fileData {
    AudioFileTypeID fileType = 0;
    
    // 读取前几个字节
    if (fileData.length >= 4) {
        const UInt8 *bytes = [fileData bytes];
        NSLog(@"file header bytes: %s", bytes);
        
        if (memcmp(bytes, "RIFF", 4) == 0) {
            fileType = kAudioFileWAVEType;
          } else if (memcmp(bytes, "ID3", 3) == 0) {
              fileType = kAudioFileMP3Type;
          } else {
              
          }
    }
    
    return fileType;
}

/// Get file type string with AudioFileTypeID.
- (nullable NSString *)getFileTypeString:(AudioFileTypeID)fileTypeID {
    NSString *fileType;
    switch (fileTypeID) {
        case kAudioFileWAVEType:
            fileType = @"wav";
            break;
        case kAudioFileMP3Type:
            fileType = @"mp3";
            
        default:
            break;
    }
    return fileType;
}

/// Correct audio file type, if file extension is not equal to true file tpye.
- (nullable NSString *)tryCorrectAudioFileTypeWithPath:(NSString *)filePath {
    NSString *fileExtension = [filePath pathExtension];
    NSString *trueFileType = [self audioFileTypeWithPath:filePath];
    if (trueFileType.length && ![trueFileType isEqualToString:fileExtension]) {
        NSString *newFilePath = [filePath stringByDeletingPathExtension];
        newFilePath = [newFilePath stringByAppendingPathExtension:trueFileType];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // If file has existed, then remove old filePath.
        if ([fileManager fileExistsAtPath:newFilePath]) {
            NSError *error = nil;
            if (![fileManager removeItemAtPath:filePath error:&error]) {
                NSLog(@"remove file error: %@", [error localizedDescription]);
                return nil;
            }
            return newFilePath;
        }
        
        
        NSError *error = nil;
        if ([fileManager moveItemAtPath:filePath toPath:newFilePath error:&error]) {
            NSLog(@"rename successful: %@", newFilePath);
            return newFilePath;
        } else {
            NSLog(@"rename failed: %@", [error localizedDescription]);
            return nil;
        }
    }
    
    return nil;
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

#pragma mark - Get file download sources

- (nullable NSArray<NSString *> *)getDownloadSourcesForFilePath:(NSString *)filePath {
    NSError *error = nil;
    
    // Ref: https://stackoverflow.com/questions/61778159/swift-how-to-get-an-image-where-from-metadata-field
    
    // 获取文件属性
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"Error getting file attributes: %@", error);
        return nil;
    }
    
    // 从文件属性中获取扩展属性
    NSDictionary *fileExtendedAttributes = attrs[kFileExtendedAttributes];
    NSData *itemWhereFroms = fileExtendedAttributes[kItemWhereFroms];
    
    if (!itemWhereFroms) {
        return nil;
    }
    
    NSString *itemWhereFromsString = [[NSString alloc] initWithData:itemWhereFroms encoding:NSASCIIStringEncoding];
    // bplist00¢_Chttps://codeload.github.com/yuenov/reader-ios/zip/refs/heads/master_$https://github.com/yuenov/reader-iosQ
    NSLog(@"itemWhereFromsString: %@", itemWhereFromsString);
    
    // 解析属性列表数据
    NSError *plistError = nil;
    NSPropertyListFormat format;
    id plistData = [NSPropertyListSerialization propertyListWithData:itemWhereFroms options:NSPropertyListImmutable format:&format error:&plistError];
    
    if (plistError) {
        NSLog(@"Error decoding property list: %@", plistError);
        return nil;
    }
    
    NSMutableArray *urls = [NSMutableArray array];
    
    if ([plistData isKindOfClass:[NSArray class]]) {
        for (NSString *urlString in (NSArray *)plistData) {
            [urls addObject:urlString];
        }
    }
    
    return [urls copy];
}

// ???: Why does not it work?
- (void)setDownloadSourceForFilePath:(NSString *)filePath sourceURLs:(NSArray<NSString *> *)URLStrings {
    NSError *error;
    NSData *URLsData = [NSPropertyListSerialization dataWithPropertyList:URLStrings format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];

    if (URLsData) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableDictionary *attrs = [[fileManager attributesOfItemAtPath:filePath error:nil] mutableCopy];
        if (!attrs) {
            attrs = [NSMutableDictionary dictionary];
        }
        
        NSMutableDictionary *extendedAttributes = [attrs[kFileExtendedAttributes] mutableCopy];
        if (!extendedAttributes) {
            extendedAttributes = [NSMutableDictionary dictionary];
        }
        extendedAttributes[kItemWhereFroms] = URLsData;
        attrs[kFileExtendedAttributes] = @{kItemWhereFroms: URLsData};
        
        if (![fileManager setAttributes:attrs ofItemAtPath:filePath error:&error]) {
            NSLog(@"Error setting download source: %@", error);
        }
        
        // Set the extended attribute using setxattr
        int result = setxattr(filePath.UTF8String, kItemWhereFroms.UTF8String, [URLsData bytes], [URLsData length], 0, 0);
        
        if (result == 0) {
            NSLog(@"Download source set successfully.");
        } else {
            NSLog(@"Error setting download source: %s", strerror(errno));
        }
    }
}

@end
