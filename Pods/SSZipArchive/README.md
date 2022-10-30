
[![Build Status](https://travis-ci.org/ZipArchive/ZipArchive.svg?branch=master)](https://travis-ci.org/ZipArchive/ZipArchive)

# SSZipArchive

ZipArchive is a simple utility class for zipping and unzipping files on iOS, macOS and tvOS.

- Unzip zip files;
- Unzip password protected zip files;
- Unzip AES encrypted zip files;
- Create zip files;
- Create password protected zip files;
- Create AES encrypted zip files;
- Choose compression level;
- Zip-up NSData instances. (with a filename)

## Installation and Setup

*The main release branch is configured to support Objective-C and Swift 3+.*

SSZipArchive works on Xcode 7-10 and above, iOS 8-12 and above, tvOS 9 and above, macOS 10.8-10.14 and above, watchOS 2 and above.

### CocoaPods
In your Podfile:  
`pod 'SSZipArchive'`

You should define your minimum deployment target explicitly, like:
`platform :ios, '8.0'`

CocoaPods version should be at least CocoaPods 1.6.0.

### Carthage
In your Cartfile:  
`github "ZipArchive/ZipArchive"`

### Manual

1. Add the `SSZipArchive` and `minizip` folders to your project.
2. Add the `libz` and `libiconv` libraries to your target.
3. Add the `Security` framework to your target.
4. Add the following GCC_PREPROCESSOR_DEFINITIONS: `HAVE_INTTYPES_H HAVE_PKCRYPT HAVE_STDINT_H HAVE_WZAES HAVE_ZLIB MZ_ZIP_NO_SIGNING $(inherited)`.

SSZipArchive requires ARC.

## Usage

### Objective-C

```objective-c
// Create
[SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:sampleDataPath];

// Unzip
[SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
```

### Swift

```swift
// Create
SSZipArchive.createZipFileAtPath(zipPath, withContentsOfDirectory: sampleDataPath)

// Unzip
SSZipArchive.unzipFileAtPath(zipPath, toDestination: unzipPath)
```

## License

SSZipArchive is protected under the [MIT license](https://github.com/samsoffes/ssziparchive/raw/master/LICENSE) and our slightly modified version of [Minizip](https://github.com/nmoinvaz/minizip) 1.2 is licensed under the [Zlib license](https://www.zlib.net/zlib_license.html).

## Acknowledgments

* Big thanks to *aish* for creating [ZipArchive](https://code.google.com/archive/p/ziparchive/). The project that inspired SSZipArchive.
* Thank you [@soffes](https://github.com/soffes) for the actual name of SSZipArchive.
* Thank you [@randomsequence](https://github.com/randomsequence) for implementing the creation support tech.
* Thank you [@johnezang](https://github.com/johnezang) for all his amazing help along the way.
* Thank you [@nmoinvaz](https://github.com/nmoinvaz) for minizip, the core of ZipArchive.
* Thank you to [all the contributors](https://github.com/ZipArchive/ZipArchive/graphs/contributors).
