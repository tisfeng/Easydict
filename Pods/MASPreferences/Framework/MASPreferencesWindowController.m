#import "MASPreferencesWindowController.h"
#import "MASPreferencesViewController.h"

NSString *const kMASPreferencesWindowControllerDidChangeViewNotification = @"MASPreferencesWindowControllerDidChangeViewNotification";

static NSString *const kMASPreferencesFrameTopLeftKey = @"MASPreferences Frame Top Left";
static NSString *const kMASPreferencesSelectedViewKey = @"MASPreferences Selected Identifier View";

static NSString * PreferencesKeyForViewBounds (NSString *identifier)
{
    return [NSString stringWithFormat:@"MASPreferences %@ Frame", identifier];
}

@interface MASPreferencesWindowController () // Private

- (NSViewController <MASPreferencesViewController> *)viewControllerForIdentifier:(NSString *)identifier;

@property (readonly) NSArray *toolbarItemIdentifiers;
@property (nonatomic, retain) NSViewController <MASPreferencesViewController> *selectedViewController;

@end

#pragma mark -

@implementation MASPreferencesWindowController

@synthesize viewControllers = _viewControllers;
@synthesize selectedViewController = _selectedViewController;
@synthesize title = _title;
@synthesize toolbar = _toolbar;

#pragma mark -

- (instancetype)initWithViewControllers:(NSArray *)viewControllers
{
    return [self initWithViewControllers:viewControllers title:nil];
}

- (instancetype)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title
{
	NSParameterAssert(viewControllers.count > 0);
    NSString *nibPath = [[NSBundle bundleForClass:MASPreferencesWindowController.class] pathForResource:@"MASPreferencesWindow" ofType:@"nib"];
    if ((self = [super initWithWindowNibPath:nibPath owner:self]))
    {
		_viewControllers = [viewControllers mutableCopy];
        _minimumViewRects = [[NSMutableDictionary alloc] init];
        _title = [title copy];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self window] setDelegate:nil];
    for (NSToolbarItem *item in [self.toolbar items]) {
        item.target = nil;
        item.action = nil;
    }
    self.toolbar.delegate = nil;
}

- (void)addViewController:(NSViewController <MASPreferencesViewController> *)viewController
{
	NSParameterAssert(viewController);
	[_viewControllers addObject: viewController];
	[_toolbar insertItemWithItemIdentifier: viewController.viewIdentifier atIndex: ([_viewControllers count] - 1)];
	[_toolbar validateVisibleItems];
}

#pragma mark -

- (void)windowDidLoad
{
    BOOL hasImages = NO;
    for (id viewController in self.viewControllers)
        if ([viewController respondsToSelector:@selector(toolbarItemImage)])
            hasImages = YES;

    if(hasImages == NO)
        [[[self window] toolbar] setDisplayMode:NSToolbarDisplayModeLabelOnly];

    if ([self.title length] > 0)
        [[self window] setTitle:self.title];

    if ([self.viewControllers count])
        self.selectedViewController = [self viewControllerForIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:kMASPreferencesSelectedViewKey]] ?: [self firstViewController];

    NSString *origin = [[NSUserDefaults standardUserDefaults] stringForKey:kMASPreferencesFrameTopLeftKey];
    if (origin)
    {
        [self.window layoutIfNeeded];
        [self.window setFrameTopLeftPoint:NSPointFromString(origin)];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMove:)   name:NSWindowDidMoveNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self.window];
}

- (NSViewController <MASPreferencesViewController> *)firstViewController {
    for (id viewController in self.viewControllers)
        if ([viewController isKindOfClass:[NSViewController class]])
            return viewController;

    return nil;
}

#pragma mark -
#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id __unused)sender
{
    return !self.selectedViewController || [self.selectedViewController commitEditing];
}

- (void)windowDidMove:(NSNotification* __unused)aNotification
{
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromPoint(NSMakePoint(NSMinX([self.window frame]), NSMaxY([self.window frame]))) forKey:kMASPreferencesFrameTopLeftKey];
}

- (void)windowDidResize:(NSNotification* __unused)aNotification
{
    NSViewController <MASPreferencesViewController> *viewController = self.selectedViewController;
    if (viewController)
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect([viewController.view bounds]) forKey:PreferencesKeyForViewBounds(viewController.viewIdentifier)];
}

#pragma mark -
#pragma mark Accessors

- (NSArray *)toolbarItemIdentifiers
{
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:_viewControllers.count];
    for (id viewController in _viewControllers)
        if (viewController == [NSNull null])
            [identifiers addObject:NSToolbarFlexibleSpaceItemIdentifier];
        else
            [identifiers addObject:[viewController viewIdentifier]];
    return identifiers;
}

#pragma mark -

- (NSUInteger)indexOfSelectedController
{
    NSUInteger index = [self.toolbarItemIdentifiers indexOfObject:self.selectedViewController.viewIdentifier];
    return index;
}

#pragma mark -
#pragma mark NSToolbarDelegate

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar * __unused)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}                   
                   
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar * __unused)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar * __unused)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar * __unused)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL __unused)flag
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSArray *identifiers = self.toolbarItemIdentifiers;
    NSUInteger controllerIndex = [identifiers indexOfObject:itemIdentifier];
    if (controllerIndex != NSNotFound)
    {
        id <MASPreferencesViewController> controller = [_viewControllers objectAtIndex:controllerIndex];
        if ([controller respondsToSelector:@selector(toolbarItemImage)])
            toolbarItem.image = controller.toolbarItemImage;
        toolbarItem.label = controller.toolbarItemLabel;
        toolbarItem.target = self;
        toolbarItem.action = @selector(toolbarItemDidClick:);
    }
    return toolbarItem;
}

#pragma mark -
#pragma mark Private methods

- (NSViewController <MASPreferencesViewController> *)viewControllerForIdentifier:(NSString *)identifier
{
    for (id viewController in self.viewControllers) {
        if (viewController == [NSNull null]) continue;
        if ([[viewController viewIdentifier] isEqualToString:identifier])
            return viewController;
    }
    return nil;
}

#pragma mark -

- (void)setSelectedViewController:(NSViewController <MASPreferencesViewController> *)controller
{
    if (_selectedViewController == controller)
        return;

    if (_selectedViewController)
    {
        // Check if we can commit changes for old controller
        if (![_selectedViewController commitEditing])
        {
            [[self.window toolbar] setSelectedItemIdentifier:_selectedViewController.viewIdentifier];
            return;
        }
        [self.window setContentView:[[NSView alloc] init]];
        [_selectedViewController setNextResponder:nil];
        // With 10.10 and later AppKit will invoke viewDidDisappear so we need to prevent it from being called twice.
        if (![NSViewController instancesRespondToSelector:@selector(viewDidDisappear)])
            if ([_selectedViewController respondsToSelector:@selector(viewDidDisappear)])
                [_selectedViewController viewDidDisappear];
        _selectedViewController = nil;
    }

    if (!controller)
        return;

    // Retrieve the new window tile from the controller view
    if ([self.title length] == 0)
    {
        NSString *label = controller.toolbarItemLabel;
        self.window.title = label;
    }

    [[self.window toolbar] setSelectedItemIdentifier:controller.viewIdentifier];

    // Record new selected controller in user defaults
    [[NSUserDefaults standardUserDefaults] setObject:controller.viewIdentifier forKey:kMASPreferencesSelectedViewKey];
    
    NSView *controllerView = controller.view;

    // Retrieve current and minimum frame size for the view
    NSString *oldViewRectString = [[NSUserDefaults standardUserDefaults] stringForKey:PreferencesKeyForViewBounds(controller.viewIdentifier)];
    NSString *minViewRectString = [_minimumViewRects objectForKey:controller.viewIdentifier];
    if (!minViewRectString)
        [_minimumViewRects setObject:NSStringFromRect(controllerView.bounds) forKey:controller.viewIdentifier];
    
    BOOL sizableWidth = ([controller respondsToSelector:@selector(hasResizableWidth)]
                         ? controller.hasResizableWidth
                         : controllerView.autoresizingMask & NSViewWidthSizable);
    BOOL sizableHeight = ([controller respondsToSelector:@selector(hasResizableHeight)]
                          ? controller.hasResizableHeight
                          : controllerView.autoresizingMask & NSViewHeightSizable);
    
    NSRect oldViewRect = oldViewRectString ? NSRectFromString(oldViewRectString) : controllerView.bounds;
    NSRect minViewRect = minViewRectString ? NSRectFromString(minViewRectString) : controllerView.bounds;
    oldViewRect.size.width  = NSWidth(oldViewRect)  < NSWidth(minViewRect)  || !sizableWidth  ? NSWidth(minViewRect)  : NSWidth(oldViewRect);
    oldViewRect.size.height = NSHeight(oldViewRect) < NSHeight(minViewRect) || !sizableHeight ? NSHeight(minViewRect) : NSHeight(oldViewRect);

    [controllerView setFrame:oldViewRect];

    // Calculate new window size and position
    NSRect oldFrame = [self.window frame];
    NSRect newFrame = [self.window frameRectForContentRect:oldViewRect];
    newFrame = NSOffsetRect(newFrame, NSMinX(oldFrame), NSMaxY(oldFrame) - NSMaxY(newFrame));

    // Setup min/max sizes and show/hide resize indicator
    [self.window setContentMinSize:minViewRect.size];
    [self.window setContentMaxSize:NSMakeSize(sizableWidth ? CGFLOAT_MAX : NSWidth(oldViewRect), sizableHeight ? CGFLOAT_MAX : NSHeight(oldViewRect))];
    [self.window setShowsResizeIndicator:sizableWidth || sizableHeight];
    [[self.window standardWindowButton:NSWindowZoomButton] setEnabled:sizableWidth || sizableHeight];

    [self.window setFrame:newFrame display:YES animate:[self.window isVisible]];
    
    _selectedViewController = controller;

    // In OSX 10.10, setContentView below calls viewWillAppear.  We still want to call viewWillAppear on < 10.10,
    // so the check below avoids calling viewWillAppear twice on 10.10.
    // See https://github.com/shpakovski/MASPreferences/issues/32 for more info.
    if (![NSViewController instancesRespondToSelector:@selector(viewWillAppear)])
        if ([controller respondsToSelector:@selector(viewWillAppear)])
            [controller viewWillAppear];
    
    [self.window setContentView:controllerView];
    [self.window recalculateKeyViewLoop];
    if ([self.window firstResponder] == self.window) {
        if ([controller respondsToSelector:@selector(initialKeyView)])
            [self.window makeFirstResponder:[controller initialKeyView]];
        else
            [self.window selectKeyViewFollowingView:controllerView];
    }
    
    // Insert view controller into responder chain on 10.9 and earlier
    if (controllerView.nextResponder != controller) {
      controller.nextResponder = controllerView.nextResponder;
      controllerView.nextResponder = controller;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kMASPreferencesWindowControllerDidChangeViewNotification object:self];
}

- (void)toolbarItemDidClick:(id)sender
{
    if ([sender respondsToSelector:@selector(itemIdentifier)])
        self.selectedViewController = [self viewControllerForIdentifier:[sender itemIdentifier]];
}

#pragma mark -
#pragma mark Public methods

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex
{
    if (NSLocationInRange(controllerIndex, NSMakeRange(0, _viewControllers.count)))
        self.selectedViewController = [self.viewControllers objectAtIndex:controllerIndex];
}

- (void)selectControllerWithIdentifier:(NSString *)identifier 
{
	NSParameterAssert(identifier.length > 0);
    self.selectedViewController = [self viewControllerForIdentifier:identifier];
}

#pragma mark -
#pragma mark Actions

- (IBAction)goNextTab:(id __unused)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];

    do { selectedIndex = (selectedIndex + 1) % numberOfControllers; }
    while ([_viewControllers objectAtIndex:selectedIndex] == [NSNull null]);

    [self selectControllerAtIndex:selectedIndex];
}

- (IBAction)goPreviousTab:(id __unused)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];

    do { selectedIndex = (selectedIndex + numberOfControllers - 1) % numberOfControllers; }
    while ([_viewControllers objectAtIndex:selectedIndex] == [NSNull null]);

    [self selectControllerAtIndex:selectedIndex];
}

@end
