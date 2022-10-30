//
// You create an application Preferences window using code like this:
//     _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title]
//
// To open the Preferences window:
//     [_preferencesWindowController showWindow:sender]
//

#import <AppKit/AppKit.h>

@protocol MASPreferencesViewController;

NS_ASSUME_NONNULL_BEGIN

/*!
 * Notification posted when you switch selected panel in Preferences.
 */
extern NSString * const kMASPreferencesWindowControllerDidChangeViewNotification;

/*!
 * Window controller for managing Preference view controllers.
 */
__attribute__((__visibility__("default")))
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface MASPreferencesWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate>
#else
@interface MASPreferencesWindowController : NSWindowController
#endif
{
@private
    NSMutableArray *_viewControllers;
    NSMutableDictionary *_minimumViewRects;
    NSString *_title;
    NSViewController <MASPreferencesViewController> *_selectedViewController;
    NSToolbar * __unsafe_unretained _toolbar;
}

/*!
 * Child view controllers in the Preferences window.
 */
@property (nonatomic, readonly) NSMutableArray *viewControllers;

/*!
 * Index of selected panel in the Preferences window.
 */
@property (nonatomic, readonly) NSUInteger indexOfSelectedController;

/*!
 * View controller representing selected panel in the Preferences window.
 */
@property (nonatomic, readonly) NSViewController <MASPreferencesViewController> *selectedViewController;

/*!
 * Optional window title provided in the initializer.
 */
@property (nonatomic, copy, readonly, nullable) NSString *title;

/*!
 * The toolbar managed by the Preferences window.
 */
@property (nonatomic, unsafe_unretained) IBOutlet NSToolbar *toolbar;

/*!
 * Creates new a window controller for Preferences with custom title.
 *
 * @param viewControllers Non-empty list of view controllers representing Preference panels.
 * @param title Optional title for the Preferneces window. Pass `nil` to show the title provided by selected view controller.
 *
 * @return A new controller with the given title.
 */
- (instancetype)initWithViewControllers:(NSArray *)viewControllers title:(NSString * _Nullable)title;
- (instancetype)init __attribute((unavailable("Please use initWithViewControllers:title:")));

/*!
 * Creates new a window controller for Preferences with a flexible title.
 *
 * @param viewControllers Non-empty list of view controllers representing Preference panels.
 *
 * @return A new controller with title depending on selected view controller.
 */
- (instancetype)initWithViewControllers:(NSArray *)viewControllers;

/*!
 * Appends new panel to the Preferences window.
 *
 * @param viewController View controller representing new panel.
 */
- (void)addViewController:(NSViewController <MASPreferencesViewController> *)viewController;

/*!
 * Changes selection in the Preferences toolbar.
 *
 * @param controllerIndex Position of the new panel to select in the toolbar.
 */
- (void)selectControllerAtIndex:(NSUInteger)controllerIndex;

/*!
 * Changes selection in the Preferences toolbar using panel identifier.
 *
 * @param identifier String identifier of the view controller to select.
 */
- (void)selectControllerWithIdentifier:(NSString *)identifier;

/*!
 * Useful action for switching to the next panel.
 *
 * For example, you may connect it to the main menu.
 *
 * @param sender Menu or toolbar item.
 */
- (IBAction)goNextTab:(id _Nullable)sender;

/*!
 * Useful action for switching to the previous panel.
 *
 * For example, you may connect it to the main menu.
 *
 * @param sender Menu or toolbar item.
 */
- (IBAction)goPreviousTab:(id _Nullable)sender;

@end

NS_ASSUME_NONNULL_END
