//
//  EZWindowPatch.h
//  Easydict
//
//  Created by asdmoment on 2026/4/26.
//  Copyright © 2026 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Patches NSWindow subclasses that directly override `_cornerMask` on macOS 26 Tahoe
/// to restore WindowServer compositor caching and reduce GPU load.
/// Must be called before SwiftUI creates any windows.
void EZPatchWindowServerCornerMask(void);

NS_ASSUME_NONNULL_END
