
If the `TreeStateRouter.platformRouting` factory is used, the router will integrate with the 
Navigator 2.0 APIs.

## Route URIs
URIs representing the current route path are reported to the platform. When targeting the web 
platform, this means the browser URL will be updated as state transitions occur.

Each active route contributes a segment to the URI, and the specific text of this segment can 
controlled by the `path` value for the route. 

```dart
final router = TreeStateRouter.platformRouting(
  stateTree: routePathsStateTree(),
  routes: [
    StateRoute.shell(
      States.root,
      path: RoutePath('root'),
      routeBuilder: rootPage,
      routes: [
        StateRoute.shell(
          States.parent1,
          path: RoutePath('parent-1'),
          routeBuilder: parent1Page,
          routes: [
            DataStateRoute<ChildData>(
              States.child1,
              // The URI path will be '/root/parent-1/child/1' when this route is active 
              path: DataRoutePath('child/1'),
              routeBuilder: child1Page,
            ),
            StateRoute(
              States.child2,
              path: RoutePath('child/2'),
              routeBuilder: child2Page,
            )
          ],
        ),
    ),
  ],
);
```

If `path` is left undefined, the `stateKey` will be used as a fallback to generate the URI segment.
This is unlikely to be appropriate for end users, so it is recommended that `path` values be 
provided for all routes. 

Note that by default, even though URIs are displayed in the browser for the current route path, 
these URIs do not support deep linking. If an attempt is made to directly enter the URL in the
browser address bar, the route will be ignored, and instead the URI will be interpreted as the 
base URL for the web app, and consequently the state machine will restart at its initial state.   


## Path Parameters
The `DataStateRoute.parameterized` factory allows values obtained from the current data value of a
data route to be included in the path. When the `pathTemplate` includes a unique name prefixed by a
`:` character.

For example
```dart
class AdddressState {
   AddressState(this.userId, this.addressId);
   final int userId;
   final int addressId;
}

DataStateRoute<ChildData>(
   States.addressState,
   path: DataRoutePath.parameterized(
      'user/:userId/address/:addressId',
      pathArgs: (data) => {
         'userId': data.userId.toString(),
         'addressId': data.addressId.toString(),
      },
   ),
```

When using `DataStateRoute.withParams`, a `pathArgs` function is required to generate a
`Map<String, String>` containing the path value for each parameter to be included in the URI. The 
function is provided the current data value of the data route as input.


## History and the Back Button
In general, `TreeStateRouter` will not generate browser history entries. As state transitions occur
the router will report new URLs to the platform, and therefore update the URL in the browser address
bar, but only a single history entry is maintained. Consequently the browser back button shoud not
be enabled, and the user will not be able to return to earlier states. 
