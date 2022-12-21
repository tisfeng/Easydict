/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULHeartbeatDateStorage.h"
#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULSecureCoding.h"

NSString *const kGULHeartbeatStorageDirectory = @"Google/FIRApp";

@interface GULHeartbeatDateStorage ()

/** The name of the file that stores heartbeat information. */
@property(nonatomic, readonly) NSString *fileName;
@end

@implementation GULHeartbeatDateStorage

@synthesize fileURL = _fileURL;

- (instancetype)initWithFileName:(NSString *)fileName {
  if (fileName == nil) return nil;

  self = [super init];
  if (self) {
    _fileName = fileName;
  }
  return self;
}

/** Lazy getter for fileURL.
 * @return fileURL where heartbeat information is stored.
 */
- (NSURL *)fileURL {
  if (!_fileURL) {
    NSURL *directoryURL = [self directoryPathURL];
    [self checkAndCreateDirectory:directoryURL];
    _fileURL = [directoryURL URLByAppendingPathComponent:_fileName];
  }
  return _fileURL;
}

/** Returns the URL path of the directory for heartbeat storage data.
 * @return the URL path of the directory for heartbeat storage data.
 */
- (NSURL *)directoryPathURL {
  NSArray<NSString *> *paths;
#if TARGET_OS_TV
  paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
#else
  paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
#endif  // TARGET_OS_TV
  NSString *rootPath = [paths lastObject];
  NSURL *rootURL = [NSURL fileURLWithPath:rootPath];
  NSURL *directoryURL = [rootURL URLByAppendingPathComponent:kGULHeartbeatStorageDirectory];
  return directoryURL;
}

/** Check for the existence of the directory specified by the URL, and create it if it does not
 * exist.
 * @param directoryPathURL The path to the directory that needs to exist.
 */
- (void)checkAndCreateDirectory:(NSURL *)directoryPathURL {
  NSError *error;
  if (![directoryPathURL checkResourceIsReachableAndReturnError:&error]) {
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryPathURL
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&error];
  }
}

- (nullable NSDate *)heartbeatDateForTag:(NSString *)tag {
  @synchronized(self.class) {
    NSDictionary *heartbeatDictionary = [self heartbeatDictionaryWithFileURL:self.fileURL];
    NSDate *heartbeatDate = heartbeatDictionary[tag];

    // Validate the value type. If the storage file was corrupted or updated with a different format
    // by a newer SDK version the value type may be different.
    if (![heartbeatDate isKindOfClass:[NSDate class]]) {
      heartbeatDate = nil;
    }

    return heartbeatDate;
  }
}

- (BOOL)setHearbeatDate:(NSDate *)date forTag:(NSString *)tag {
  // Synchronize on the class to ensure that the different instances of the class will not access
  // the same file concurrently.
  // TODO: Consider a different synchronization strategy here and in `-heartbeatDateForTag:` method.
  // Currently no heartbeats can be read/written concurrently even if they are in different files.
  @synchronized(self.class) {
    NSMutableDictionary *heartbeatDictionary =
        [[self heartbeatDictionaryWithFileURL:self.fileURL] mutableCopy];
    heartbeatDictionary[tag] = date;
    NSError *error;
    BOOL isSuccess = [self writeDictionary:[heartbeatDictionary copy]
                             forWritingURL:self.fileURL
                                     error:&error];
    return isSuccess;
  }
}

- (NSDictionary *)heartbeatDictionaryWithFileURL:(NSURL *)readingFileURL {
  NSDictionary *heartbeatDictionary;

  NSError *error;
  NSData *objectData = [NSData dataWithContentsOfURL:readingFileURL options:0 error:&error];

  if (objectData.length > 0 && error == nil) {
    NSSet<Class> *objectClasses =
        [NSSet setWithArray:@[ NSDictionary.class, NSDate.class, NSString.class ]];
    heartbeatDictionary = [GULSecureCoding unarchivedObjectOfClasses:objectClasses
                                                            fromData:objectData
                                                               error:&error];
  }

  if (heartbeatDictionary.count == 0 || error != nil) {
    heartbeatDictionary = [NSDictionary dictionary];
  }

  return heartbeatDictionary;
}

- (BOOL)writeDictionary:(NSDictionary *)dictionary
          forWritingURL:(NSURL *)writingFileURL
                  error:(NSError **)outError {
  // Archive a mutable copy `dictionary` for writing to disk. This is done for
  // backwards compatibility. See Google Utilities issue #36 for more context.
  // TODO: Remove usage of mutable copy in a future version of Google Utilities.
  NSData *data = [GULSecureCoding archivedDataWithRootObject:[dictionary mutableCopy]
                                                       error:outError];
  if (data.length == 0) {
    return NO;
  }

  return [data writeToURL:writingFileURL atomically:YES];
}

@end
