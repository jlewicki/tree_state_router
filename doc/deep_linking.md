A route can be enabled for deep-linking by setting `enableDeepLink` to `true` when specifying the 
`path` for the route. If the application is launched with a deep-link URI, and that URI corresponds
to a deep-link enabled route, the state machine will be transitioned to the corresponding state for 
the deep link route.  

When following a deep link, any query parameters thay are included in the deep link URI are 
accessible in `StateRoutingContext.queryParameters`.

It should be noted that enabling deep linking for a route effectively introduces state transitions 
that are not defined by the underlying state tree in use by the router. While in many cases this is
desirable, care should be taken ensure that invariants established and expected by the state tree 
are not violated when enabling a route for linking.