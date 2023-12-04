// Copyright (c) 2017 Landon J. Fuller <landon@landonf.org>
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// Comment from
// <a href="http://iphonedevwiki.net/index.php/Crack_prevention">iPhone Dev
// Wiki Crack Prevention</a>:
// App Store binaries are signed by both their developer and Apple. This
// encrypts the binary so that decryption keys are needed in order to make the
// binary readable. When iOS executes the binary, the decryption keys are used
// to decrypt the binary into a readable state where it is then loaded into
// memory and executed. iOS can tell the encryption status of a binary via the
// cryptid structure member of LC_ENCRYPTION_INFO MachO load command. If
// cryptid is a non-zero value then the binary is encrypted.
//
// 'Cracking' works by letting the kernel decrypt the binary then siphoning the
// decrypted data into a new binary file, resigning, and repackaging. This will
// only work on jailbroken devices as codesignature validation has been
// removed. Resigning takes place because while the codesignature doesn't have
// to be valid thanks to the jailbreak, it does have to be in place unless you
// have AppSync or similar to disable codesignature checks.
//
// More information at
// <a href="http://landonf.org/2009/02/index.html">Landon Fuller's blog</a>

#import "third_party/IsAppEncrypted/Public/IsAppEncrypted.h"

#import <mach-o/dyld.h>
#import <objc/objc.h>

/// The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from
/// the iPhoneOS or Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just
/// provide the definitions here.
#if TARGET_OS_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
  uint32_t cmd;
  uint32_t cmdsize;
  uint32_t cryptoff;
  uint32_t cryptsize;
  uint32_t cryptid;
};
#endif

BOOL IsAppEncrypted(void) {
  const struct mach_header *executableHeader = NULL;
  for (uint32_t i = 0; i < _dyld_image_count(); i++) {
    const struct mach_header *header = _dyld_get_image_header(i);
    if (header && header->filetype == MH_EXECUTE) {
      executableHeader = header;
      break;
    }
  }

  if (!executableHeader) {
    return NO;
  }

  BOOL is64bit = (executableHeader->magic == MH_MAGIC_64);
  uintptr_t cursor = (uintptr_t)executableHeader +
                     (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
  const struct segment_command *segmentCommand = NULL;
  uint32_t i = 0;

  while (i++ < executableHeader->ncmds) {
    segmentCommand = (struct segment_command *)cursor;

    if (!segmentCommand) {
      continue;
    }

    if ((!is64bit && segmentCommand->cmd == LC_ENCRYPTION_INFO) ||
        (is64bit && segmentCommand->cmd == LC_ENCRYPTION_INFO_64)) {
      if (is64bit) {
        struct encryption_info_command_64 *cryptCmd =
            (struct encryption_info_command_64 *)segmentCommand;
        return cryptCmd && cryptCmd->cryptid != 0;
      } else {
        struct encryption_info_command *cryptCmd = (struct encryption_info_command *)segmentCommand;
        return cryptCmd && cryptCmd->cryptid != 0;
      }
    }
    cursor += segmentCommand->cmdsize;
  }

  return NO;
}
