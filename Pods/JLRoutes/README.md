JLRoutes
========

[![Platforms](https://img.shields.io/cocoapods/p/JLRoutes.svg?style=flat)](http://cocoapods.org/pods/JLRoutes)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/JLRoutes.svg)](http://cocoapods.org/pods/JLRoutes)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/joeldev/JLRoutes.svg?branch=master)](https://travis-ci.org/joeldev/JLRoutes)
[![Apps](https://img.shields.io/cocoapods/at/JLRoutes.svg?maxAge=2592000)](https://cocoapods.org/pods/JLRoutes)

### What is it? ###
JLRoutes is a URL routing library with a simple block-based API. It is designed to make it very easy to handle complex URL schemes in your application with minimal code.

### Installation ###
JLRoutes is available for installation using [CocoaPods](https://cocoapods.org/pods/JLRoutes) or Carthage (add `github "joeldev/JLRoutes"` to your `Cartfile`).

### Requirements ###
JLRoutes 2.x require iOS 8.0+ or macOS 10.10+. If you need to support iOS 7 or macOS 10.9, please use version 1.6.4 (which is the last 1.x release).

### Documentation ###
Documentation is available [here](http://cocoadocs.org/docsets/JLRoutes/).

### Getting Started ###

[Configure your URL schemes in Info.plist.](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW2)

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  JLRoutes *routes = [JLRoutes globalRoutes];

  [routes addRoute:@"/user/view/:userID" handler:^BOOL(NSDictionary *parameters) {
    NSString *userID = parameters[@"userID"]; // defined in the route by specifying ":userID"

    // present UI for viewing user with ID 'userID'

    return YES; // return YES to say we have handled the route
  }];

  return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options
{
  return [JLRoutes routeURL:url];
}
```

Routes can also be registered with subscripting syntax:
```objc
JLRoutes.globalRoutes[@"/user/view/:userID"] = ^BOOL(NSDictionary *parameters) {
  // ...
};
```

After adding a route for `/user/view/:userID`, the following call will cause the handler block to be called with a dictionary containing `@"userID": @"joeldev"`:
```objc
NSURL *viewUserURL = [NSURL URLWithString:@"myapp://user/view/joeldev"];
[JLRoutes routeURL:viewUserURL];
```

### The Parameters Dictionary ###

The parameters dictionary always contains at least the following three keys:
```json
{
  "JLRouteURL":  "(the NSURL that caused this block to be fired)",
  "JLRoutePattern": "(the actual route pattern string)",
  "JLRouteScheme": "(the route scheme, defaults to JLRoutesGlobalRoutesScheme)"
}
```

The JLRouteScheme key refers to the scheme that the matched route lives in. [Read more about schemes.](https://github.com/joeldev/JLRoutes#scheme-namespaces)

See JLRoutes.h for the list of constants.

### Handler Block Chaining ###

The handler block is expected to return a boolean for if it has handled the route or not. If the block returns `NO`, JLRoutes will behave as if that route is not a match and it will continue looking for a match. A route is considered to be a match if the pattern string matches **and** the block returns `YES`.

It is also important to note that if you pass nil for the handler block, an internal handler block will be created that simply returns `YES`.

### Global Configuration ###

There are multiple global configuration options available to help customize JLRoutes behavior for a particular use-case. All options only take affect for the next operation.

```objc
/// Configures verbose logging. Defaults to NO.
+ (void)setVerboseLoggingEnabled:(BOOL)loggingEnabled;

/// Configures if '+' should be replaced with spaces in parsed values. Defaults to YES.
+ (void)setShouldDecodePlusSymbols:(BOOL)shouldDecode;

/// Configures if URL host is always considered to be a path component. Defaults to NO.
+ (void)setAlwaysTreatsHostAsPathComponent:(BOOL)treatsHostAsPathComponent;

/// Configures the default class to use when creating route definitions. Defaults to JLRRouteDefinition.
+ (void)setDefaultRouteDefinitionClass:(Class)routeDefinitionClass;
```

These are all configured at the `JLRoutes` class level:
```objc
[JLRoutes setAlwaysTreatsHostAsPathComponent:YES];
```

### More Complex Example ###

```objc
[[JLRoutes globalRoutes] addRoute:@"/:object/:action/:primaryKey" handler:^BOOL(NSDictionary *parameters) {
  NSString *object = parameters[@"object"];
  NSString *action = parameters[@"action"];
  NSString *primaryKey = parameters[@"primaryKey"];
  // stuff
  return YES;
}];
```

This route would match things like `/user/view/joeldev` or `/post/edit/123`. Let's say you called `/post/edit/123` with some URL params as well:

```objc
NSURL *editPost = [NSURL URLWithString:@"myapp://post/edit/123?debug=true&foo=bar"];
[JLRoutes routeURL:editPost];
```

The parameters dictionary that the handler block receives would contain the following key/value pairs:
```json
{
  "object": "post",
  "action": "edit",
  "primaryKey": "123",
  "debug": "true",
  "foo": "bar",
  "JLRouteURL": "myapp://post/edit/123?debug=true&foo=bar",
  "JLRoutePattern": "/:object/:action/:primaryKey",
  "JLRouteScheme": "JLRoutesGlobalRoutesScheme"
}
```

### Schemes ###

JLRoutes supports setting up routes within a specific URL scheme. Routes that are set up within a scheme can only be matched by URLs that use a matching URL scheme. By default, all routes go into the global scheme.

```objc
[[JLRoutes globalRoutes] addRoute:@"/foo" handler:^BOOL(NSDictionary *parameters) {
  // This block is called if the scheme is not 'thing' or 'stuff' (see below)
  return YES;
}];

[[JLRoutes routesForScheme:@"thing"] addRoute:@"/foo" handler:^BOOL(NSDictionary *parameters) {
  // This block is called for thing://foo
  return YES;
}];

[[JLRoutes routesForScheme:@"stuff"] addRoute:@"/foo" handler:^BOOL(NSDictionary *parameters) {
  // This block is called for stuff://foo
  return YES;
}];
```

This example shows that you can declare the same routes in different schemes and handle them with different callbacks on a per-scheme basis.

Continuing with this example, if you were to add the following route:

```objc
[[JLRoutes globalRoutes] addRoute:@"/global" handler:^BOOL(NSDictionary *parameters) {
  return YES;
}];
```

and then try to route the URL `thing://global`, it would not match because that route has not been declared within the `thing` scheme but has instead been declared within the global scheme (which we'll assume is how the developer wants it). However, you can easily change this behavior by setting the following property to `YES`:

```objc
[JLRoutes routesForScheme:@"thing"].shouldFallbackToGlobalRoutes = YES;
```

This tells JLRoutes that if a URL cannot be routed within the `thing` scheme (aka, it starts with `thing:` but no appropriate route can be found), try to recover by looking for a matching route in the global routes scheme as well. After setting that property to `YES`, the URL `thing://global` would be routed to the `/global` handler block.


### Wildcards ###

JLRoutes supports setting up routes that will match an arbitrary number of path components at the end of the routed URL. An array containing the additional path components will be added to the parameters dictionary with the key `JLRouteWildcardComponentsKey`.

For example, the following route would be triggered for any URL that started with `/wildcard/`, but would be rejected by the handler if the next component wasn't `joker`.

```objc
[[JLRoutes globalRoutes] addRoute:@"/wildcard/*" handler:^BOOL(NSDictionary *parameters) {
  NSArray *pathComponents = parameters[JLRouteWildcardComponentsKey];
  if (pathComponents.count > 0 && [pathComponents[0] isEqualToString:@"joker"]) {
    // the route matched; do stuff
    return YES;
  }

  // not interested unless 'joker' is in it
  return NO;
}];
```

### Optional Routes ###

JLRoutes supports setting up routes with optional parameters. At the route registration moment, JLRoute will register multiple routes with all combinations of the route with the optional parameters and without the optional parameters. For example, for the route `/the(/foo/:a)(/bar/:b)`, it will register the following routes:

- `/the/foo/:a/bar/:b`
- `/the/foo/:a`
- `/the/bar/:b`
- `/the`

### Querying Routes ###

There are multiple ways to query routes for programmatic uses (such as powering a debug UI). There's a method to get the full set of routes across all schemes and another to get just the specific list of routes for a given scheme. One note, you'll have to import `JLRRouteDefinition.h` as it is forward-declared.

```objc
/// All registered routes, keyed by scheme
+ (NSDictionary <NSString *, NSArray <JLRRouteDefinition *> *> *)allRoutes;

/// Return all registered routes in the receiving scheme namespace.
- (NSArray <JLRRouteDefinition *> *)routes;
```

### Handler Block Helper ###

`JLRRouteHandler` is a helper class for creating handler blocks intended to be passed to an addRoute: call.

This is specifically useful for cases in which you want a separate object or class to be the handler for a deeplink route. An example might be a view controller that you want to instantiate and present in response to a deeplink being opened.

In order to take advantage of this helper, your target class must conform to the `JLRRouteHandlerTarget` protocol. For example:

```objc
@interface MyTargetViewController : UIViewController <JLRRouteHandlerTarget>

@property (nonatomic, copy) NSDictionary <NSString *, id> *parameters;

@end


@implementation MyTargetViewController

- (instancetype)initWithRouteParameters:(NSDictionary <NSString *, id> *)parameters
{
  self = [super init];

  _parameters = [parameters copy]; // hold on to do something with later on

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // do something interesting with self.parameters, initialize views, etc...
}

@end
```

To hook this up via `JLRRouteHandler`, you could do something like this:

```objc
id handlerBlock = [JLRRouteHandler handlerBlockForTargetClass:[MyTargetViewController class] completion:^BOOL (MyTargetViewController *viewController) {
  // Push the created view controller onto the nav controller
  [self.navigationController pushViewController:viewController animated:YES];
  return YES;
}];

[[JLRoutes globalRoutes] addRoute:@"/some/route" handler:handlerBlock];
```

There's also a `JLRRouteHandler` convenience method for easily routing to an existing instance of an object vs creating a new instance. For example:

```objc
MyTargetViewController *rootController = ...; // some object that exists and conforms to JLRRouteHandlerTarget.
id handlerBlock = [JLRRouteHandler handlerBlockForWeakTarget:rootController];

[[JLRoutes globalRoutes] addRoute:@"/some/route" handler:handlerBlock];
```

When the route is matched, it will call a method on the target object:

```objc
- (BOOL)handleRouteWithParameters:(NSDictionary<NSString *, id> *)parameters;
```

These two mechanisms (weak target and class target) provide a few other ways to organize deep link handlers without writing boilerplate code for each handler or otherwise having to solve that for each app that integrates JLRoutes.

### Custom Route Parsing ###

It is possible to control how routes are parsed by subclassing `JLRRouteDefinition` and using the `addRoute:` method to add instances of your custom subclass.

```objc
// Custom route defintion that always matches
@interface AlwaysMatchRouteDefinition : JLRRouteDefinition
@end


@implementation AlwaysMatchRouteDefinition

- (JLRRouteResponse *)routeResponseForRequest:(JLRRouteRequest *)request
{
  // This method is called when JLRoutes is trying to determine if we are a match for the given request object.

  // Create the parameters dictionary
  NSDictionary *variables = [self routeVariablesForRequest:request];
  NSDictionary *matchParams = [self matchParametersForRequest:request routeVariables:variables];

  // Return a valid match!
  return [JLRRouteResponse validMatchResponseWithParameters:matchParams];
}

@end
```

This route can now be created an added:
```objc
id handlerBlock = ... // assume exists
AlwaysMatchRouteDefinition *alwaysMatch = [[AlwaysMatchRouteDefinition alloc] initWithPattern:@"/foo" priority:0 handlerBlock:handlerBlock];
[[JLRoutes globalRoutes] addRoute:alwaysMatch];
```

Alternatively, if you've written a custom route definition and want JLRoutes to always use it when adding a route (using one of the `addRoute:` methods that takes in raw parameters), use `+setDefaultRouteDefinitionClass:` to configure it as the routing definition class:
```objc
[JLRoutes setDefaultRouteDefinitionClass:[MyCustomRouteDefinition class]];
```

### License ###
BSD 3-clause. See the [LICENSE](LICENSE) file for details.

