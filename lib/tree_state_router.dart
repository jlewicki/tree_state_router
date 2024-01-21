/// A routing library that supports declarative routing based on the state transitions of a
/// `TreeStateMachine`.
library tree_state_router;

export 'src/pages.dart'
    hide
        PageBuilder,
        materialPageBuilder,
        cupertinoPageBuilder,
        materialPopupPageBuilder,
        cupertinoPopupPageBuilder,
        TransitionsBuilderPageRoute;
export 'src/routes/data_routes.dart';
export 'src/routes/route_info.dart';
export 'src/routes/route_path_info.dart' hide UriPathMatch;
export 'src/routes/routes.dart' hide CreateRouteConfig;
export 'src/widgets/descendant_states_router.dart';
export 'src/widgets/inspector.dart';
export 'src/widgets/state_routing_context_provider.dart';
export 'src/extensions.dart';
export 'src/route_parser.dart' hide TreeStateRouteInformationParser;
export 'src/router_config.dart' hide GoToDeepLink, InitializeStateDataFilter;

// To publish:
// dart pub publish --dry-run
// git tag -a vX.X.X -m "Publish vX.X.X"
// git push origin vX.X.X
// dart pub publish
//
// If you mess up
// git tag -d vX.X.X
// git push --delete origin vX.X.X
