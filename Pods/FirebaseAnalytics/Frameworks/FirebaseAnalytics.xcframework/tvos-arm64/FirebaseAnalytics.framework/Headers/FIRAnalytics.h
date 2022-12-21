#import <Foundation/Foundation.h>

#import "FIREventNames.h"
#import "FIRParameterNames.h"
#import "FIRUserPropertyNames.h"

NS_ASSUME_NONNULL_BEGIN

/// The top level Firebase Analytics singleton that provides methods for logging events and setting
/// user properties. See <a href="http://goo.gl/gz8SLz">the developer guides</a> for general
/// information on using Firebase Analytics in your apps.
///
/// @note The Analytics SDK uses SQLite to persist events and other app-specific data. Calling
///     certain thread-unsafe global SQLite methods like `sqlite3_shutdown()` can result in
///     unexpected crashes at runtime.
NS_SWIFT_NAME(Analytics)
@interface FIRAnalytics : NSObject

/// Logs an app event. The event can have up to 25 parameters. Events with the same name must have
/// the same parameters. Up to 500 event names are supported. Using predefined events and/or
/// parameters is recommended for optimal reporting.
///
/// The following event names are reserved and cannot be used:
/// <ul>
///     <li>ad_activeview</li>
///     <li>ad_click</li>
///     <li>ad_exposure</li>
///     <li>ad_query</li>
///     <li>ad_reward</li>
///     <li>adunit_exposure</li>
///     <li>app_background</li>
///     <li>app_clear_data</li>
///     <li>app_exception</li>
///     <li>app_remove</li>
///     <li>app_store_refund</li>
///     <li>app_store_subscription_cancel</li>
///     <li>app_store_subscription_convert</li>
///     <li>app_store_subscription_renew</li>
///     <li>app_update</li>
///     <li>app_upgrade</li>
///     <li>dynamic_link_app_open</li>
///     <li>dynamic_link_app_update</li>
///     <li>dynamic_link_first_open</li>
///     <li>error</li>
///     <li>firebase_campaign</li>
///     <li>first_open</li>
///     <li>first_visit</li>
///     <li>in_app_purchase</li>
///     <li>notification_dismiss</li>
///     <li>notification_foreground</li>
///     <li>notification_open</li>
///     <li>notification_receive</li>
///     <li>os_update</li>
///     <li>session_start</li>
///     <li>session_start_with_rollout</li>
///     <li>user_engagement</li>
/// </ul>
///
/// @param name The name of the event. Should contain 1 to 40 alphanumeric characters or
///     underscores. The name must start with an alphabetic character. Some event names are
///     reserved. See FIREventNames.h for the list of reserved event names. The "firebase_",
///     "google_", and "ga_" prefixes are reserved and should not be used. Note that event names are
///     case-sensitive and that logging two events whose names differ only in case will result in
///     two distinct events. To manually log screen view events, use the `screen_view` event name.
/// @param parameters The dictionary of event parameters. Passing `nil` indicates that the event has
///     no parameters. Parameter names can be up to 40 characters long and must start with an
///     alphabetic character and contain only alphanumeric characters and underscores. Only String,
///     Int, and Double parameter types are supported. String parameter values can be up to 100
///     characters long. The "firebase_", "google_", and "ga_" prefixes are reserved and should not
///     be used for parameter names.
+ (void)logEventWithName:(NSString *)name
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
    NS_SWIFT_NAME(logEvent(_:parameters:));

/// Sets a user property to a given value. Up to 25 user property names are supported. Once set,
/// user property values persist throughout the app lifecycle and across sessions.
///
/// The following user property names are reserved and cannot be used:
/// <ul>
///     <li>first_open_time</li>
///     <li>last_deep_link_referrer</li>
///     <li>user_id</li>
/// </ul>
///
/// @param value The value of the user property. Values can be up to 36 characters long. Setting the
///     value to `nil` removes the user property.
/// @param name The name of the user property to set. Should contain 1 to 24 alphanumeric characters
///     or underscores and must start with an alphabetic character. The "firebase_", "google_", and
///     "ga_" prefixes are reserved and should not be used for user property names.
+ (void)setUserPropertyString:(nullable NSString *)value forName:(NSString *)name
    NS_SWIFT_NAME(setUserProperty(_:forName:));

/// Sets the user ID property. This feature must be used in accordance with
/// <a href="https://www.google.com/policies/privacy">Google's Privacy Policy</a>
///
/// @param userID The user ID to ascribe to the user of this app on this device, which must be
///     non-empty and no more than 256 characters long. Setting userID to `nil` removes the user ID.
+ (void)setUserID:(nullable NSString *)userID;

/// Sets whether analytics collection is enabled for this app on this device. This setting is
/// persisted across app sessions. By default it is enabled.
///
/// @param analyticsCollectionEnabled A flag that enables or disables Analytics collection.
+ (void)setAnalyticsCollectionEnabled:(BOOL)analyticsCollectionEnabled;

/// Sets the interval of inactivity in seconds that terminates the current session. The default
/// value is 1800 seconds (30 minutes).
///
/// @param sessionTimeoutInterval The custom time of inactivity in seconds before the current
///     session terminates.
+ (void)setSessionTimeoutInterval:(NSTimeInterval)sessionTimeoutInterval;

/// Asynchronously retrieves the identifier of the current app session.
///
/// The session ID retrieval could fail due to Analytics collection disabled, app session expired,
/// etc.
///
/// @param completion The completion handler to call when the session ID retrieval is complete. This
///     handler is executed on a system-defined global concurrent queue.
///     This completion handler takes the following parameters:
///     <b>sessionID</b> The identifier of the current app session. The value is undefined if the
///         request failed.
///     <b>error</b> An error object that indicates why the request failed, or `nil` if the request
///         was successful.
+ (void)sessionIDWithCompletion:(void (^)(int64_t sessionID, NSError *_Nullable error))completion;

/// Returns the unique ID for this instance of the application or `nil` if
/// `ConsentType.analyticsStorage` has been set to `ConsentStatus.denied`.
///
/// @see `FIRAnalytics+Consent.h`
+ (nullable NSString *)appInstanceID;

/// Clears all analytics data for this instance from the device and resets the app instance ID.
+ (void)resetAnalyticsData;

/// Adds parameters that will be set on every event logged from the SDK, including automatic ones.
/// The values passed in the parameters dictionary will be added to the dictionary of default event
/// parameters. These parameters persist across app runs. They are of lower precedence than event
/// parameters, so if an event parameter and a parameter set using this API have the same name, the
/// value of the event parameter will be used. The same limitations on event parameters apply to
/// default event parameters.
///
/// @param parameters Parameters to be added to the dictionary of parameters added to every event.
///     They will be added to the dictionary of default event parameters, replacing any existing
///     parameter with the same name. Valid parameters are String, Int, and Double. Setting a key's
///     value to `NSNull()` will clear that parameter. Passing in a `nil` dictionary will clear all
///     parameters.
+ (void)setDefaultEventParameters:(nullable NSDictionary<NSString *, id> *)parameters;

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
