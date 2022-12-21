#import <Foundation/Foundation.h>

#import "FIRAnalytics.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides App Delegate handlers to be used in your App Delegate.
///
/// To save time integrating Firebase Analytics in an application, Firebase Analytics does not
/// require delegation implementation from the AppDelegate if neither SwiftUI nor UIScene lifecycle
/// is adopted. Instead this is automatically done by Firebase Analytics. Should you choose instead
/// to delegate manually, you can turn off the App Delegate Proxy by adding
/// FirebaseAppDelegateProxyEnabled into your app's Info.plist and setting it to boolean `NO`, and
/// adding the methods in this category to corresponding delegation handlers.
///
/// To handle Universal Links, you must return `true` in
/// `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.
@interface FIRAnalytics (AppDelegate)

/// Handles events related to a URL session that are waiting to be processed.
///
/// 1. If SwiftUI lifecycle is adopted, call this method from
/// `UIApplicationDelegate.application(_:handleEventsForBackgroundURLSession:completionHandler:)`
/// in your app delegate.
///
/// 2. If SwiftUI lifecycle is not adopted, Firebase Analytics does not require delegation
/// implementation from the AppDelegate. If you choose instead to delegate manually, you can set
/// FirebaseAppDelegateProxyEnabled to boolean `NO` in your app's Info.plist and call this method
/// from
/// `UIApplicationDelegate.application(_:handleEventsForBackgroundURLSession:completionHandler:)`
/// in your app delegate.
///
/// @param identifier The identifier of the URL session requiring attention.
/// @param completionHandler The completion handler to call when you finish processing the events.
///     Calling this completion handler lets the system know that your app's user interface is
///     updated and a new snapshot can be taken.
+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier
                          completionHandler:(nullable void (^)(void))completionHandler;

/// Handles the event when the app is launched by a URL (custom URL scheme or universal link).
///
/// 1. If SwiftUI lifecycle is adopted, use `onOpenURL(perform:)` to register a handler and call
/// this method in the handler.
///
/// 2. If UIScene lifecycle is adopted, call this method from
/// `UISceneDelegate.scene(_:willConnectTo:options:)` and
/// `UISceneDelegate.scene(_:openURLContexts:)` when the URL contexts are available.
///
/// 3. If neither SwiftUI nor UIScene lifecycle is adopted, Firebase Analytics does not require
/// delegation implementation from the AppDelegate. If you choose instead to delegate manually, you
/// can set FirebaseAppDelegateProxyEnabled to boolean `NO` in your app's Info.plist and call this
/// method from `UIApplicationDelegate.application(_:open:options:)` in your app delegate.
///
/// @param url The URL resource to open. This resource can be a network resource or a file.
+ (void)handleOpenURL:(NSURL *)url;

/// Handles the event when the app receives data associated with user activity that includes a
/// Universal Link.
///
/// 1. If SwiftUI lifecycle is adopted, use `onOpenURL(perform:)` to register a handler and call
/// `Analytics.handleOpen(_:)` instead in the handler.
///
/// 2. If UIScene lifecycle is adopted, call this method from
/// `UISceneDelegate.scene(_:willConnectTo:options:)` and `UISceneDelegate.scene(_:continue:)` when
/// NSUserActivity is available. See the [Apple
/// doc](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app) for
/// more details.
///
/// 3. If neither SwiftUI nor UIScene lifecycle is adopted, Firebase Analytics does not require
/// delegation implementation from the AppDelegate. If you choose instead to delegate manually, you
/// can set FirebaseAppDelegateProxyEnabled to boolean `NO` in your app's Info.plist and call this
/// method from `UIApplication.application(_:continue:restorationHandler:)` in your app delegate.
///
/// @param userActivity The activity object containing the data associated with the task the user
///     was performing.
+ (void)handleUserActivity:(id)userActivity;

@end

NS_ASSUME_NONNULL_END
