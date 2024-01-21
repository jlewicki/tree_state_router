import 'package:logging/logging.dart';
import 'package:tree_state_router/src/router_config.dart';
import 'package:tree_state_router/tree_state_router.dart';

/// A function that can build a map of parameter values that will be used when
/// generating a URI from a [RoutePath.pathTemplate].
typedef GeneratePathArgs = Map<String, String> Function();

/// A function that can build a map of parameter values that will be used when
/// generating a URI from a [DataRoutePath.pathTemplate]. The function is
/// provided the current data value of the data route.
typedef GenerateDataPathArgs<D> = Map<String, String> Function(D data);

/// A function that can build a generate an initial state data value from path
/// arguments parsed from a URI. This is used if a data route has been declared
/// as eligible for deep-linking.
typedef GenerateInitialData<D> = D Function(Map<String, String> pathArgs);

class UriPathMatch {
  UriPathMatch(this.pathMatch, this.initialData);
  final String pathMatch;
  final Object? initialData;
}

// Path patterns are generally like this:
//   user
//   user/1/address/2
//   user/:userId/address/:addressId
// They cant start or end with /, \
// They cant contain \
final _pathTemplateRegEx =
    RegExp(r'^([^\\\/\s]{1}|[^\\\/\s]+[^\\]*[^\\\/\s]+)$');

// Identifies the parameters in a path like user/:userId/address/:addressId
// The parameter pattern has to be followed by a / (or be at end of the text)
final _pathParamsRegEx = RegExp(r':(\w+)(\((?:\\.|[^\\()])+\))?');

/// A description of the URI path segment for a state route, when a route tree
/// is enabled for platform routing with [TreeStateRouter.platformRouting].
///
/// The path can be a literal path like `user`, or contain parameters that
/// are prefixed by `:`, like `user/:userId`. When the router needs to generate
/// a URI representing a route path, it will call [generateUriPath] for each
/// active route path, passing the active data value (if any) for the route.
/// This data value can be used to generate values for the path parameters.
///
/// A path can be enabled for deep linking with [enableDeepLink]. By default,
/// a path does not support for deep linking. That is, [generateUriPath] will be
/// used when generate URIs as the active route changes, but will not support
/// navigating directly to the route when following a deep link. If
/// [enableDeepLink] is `true`, then additionally [matchUriPath] will used when
/// parsing a deep link URI.
sealed class RoutePathInfo {
  /// Constructs a [RoutePathInfo].
  RoutePathInfo(
    this.pathTemplate,
    this.parameters, {
    this.enableDeepLink = false,
  }) : assert(pathTemplate.isNotEmpty, 'pathTemplate cannot be empty');

  /// The path template to use for the associated route, when a routing URI
  /// needs to be generated.
  ///
  /// This can be a literal, such as `user`, or can potentially contain one or
  /// more parameters, prefixed by a colon. For example:
  /// `user/:userId/address/:addressId`
  final String pathTemplate;

  /// The names of parameters in [pathTemplate].
  ///
  /// If [pathTemplate] includes any parameters, the names of the parameters
  /// are included in this list.  For example, if [pathTemplate] is
  /// `user/:userId/address/:addressId`, then [parameters] will contain `userId`
  /// and `addressId`.
  final List<String> parameters;

  /// Indicates if the route supports deep linking.
  final bool enableDeepLink;

  /// A regex pattern representing [pathTemplate] that includes a named capture
  /// group for each parameter in the template.
  late final String _uriPathPattern = _replaceTemplateParameters((paramName) {
    // Replace the :paramName token with a named capture group that can match
    // capture the parameter value when it occurs within a URI path
    return '(?<$paramName>[^/]+)';
  });

  late final _uriPathRegEx = RegExp('^/$_uriPathPattern', caseSensitive: false);

  /// Generates a path string representing this for use in a URI.
  ///
  /// The state [data] for the data state associated with this route path is
  /// provided, or `null` if the state is not a data state. This data can be
  /// use when determining values for parameters in the path template.
  String generateUriPath(dynamic data) {
    var pathArgs = _generatePathArgs(data);
    // TODO: find a way to replace parms without repeatedly running regexp?
    return _replaceTemplateParameters((paramName) {
      var pathArg = pathArgs[paramName];
      if (pathArg == null) {
        throw RoutePathError(
            'Missing argument value for path parameter $paramName for '
            'path $pathTemplate');
      }
      return pathArg;
    });
  }

  /// Attempts to match the [uriPath] against this route path
  ///
  /// If the match succeeds, a [UriPathMatch] describing the match is returned.
  /// Otherwise, `null` is returned.
  UriPathMatch? matchUriPath(String uriPath) {
    var matches = _uriPathRegEx.allMatches(uriPath).toList();
    if (matches.isNotEmpty) {
      var match = matches[0];
      assert(match.start == 0);
      var pathArgs = Map.fromEntries(parameters.map((paramName) {
        var paramValue = match.namedGroup(paramName);
        assert(paramValue != null);
        return MapEntry(paramName, paramValue!);
      }));
      var initialData = _generateInitialData(pathArgs);
      return UriPathMatch(
        uriPath.substring(match.start, match.end),
        initialData,
      );
    }
    return null;
  }

  Map<String, String> _generatePathArgs(dynamic data);

  String _replaceTemplateParameters(
    String Function(String paramName) replaceParam,
  ) {
    var sb = StringBuffer();
    var idx = 0;
    var matches = _pathParamsRegEx.allMatches(pathTemplate).toList();
    if (matches.isNotEmpty) {
      for (var match in matches) {
        sb.write(pathTemplate.substring(idx, match.start));
        // Match 0 is :arg, Match 1 is arg (no colon prefix)
        var paramName = match[1]!;
        var pathArg = replaceParam(paramName);
        sb.write(pathArg);
        idx = match.end;
      }
    }

    if (idx < pathTemplate.length) {
      sb.write(pathTemplate.substring(idx));
    }

    return sb.toString();
  }

  Object? _generateInitialData(Map<String, String> pathArgs);
}

/// Describes how a [StateRoute] integrates with platform (i.e. Navigator 2.0)
/// routing.
///
/// {@category Web Apps}
/// {@category Deep Linking}
class RoutePath extends RoutePathInfo {
  RoutePath._(
    super.pathTemplate,
    super.parameters,
    this.generatePathArgs, {
    super.enableDeepLink,
  }) : assert(
          _pathTemplateRegEx.hasMatch(pathTemplate),
          'Invalid pathTemplate',
        );

  /// Constructs a [RoutePath] with a literal [pathTemplate].
  ///
  /// {@template RoutePath.enableDeepLink}
  /// If [enableDeepLink] is true, the associated route can be navigated to
  /// directly when the application receives a deep link to the route from the
  /// platform.
  /// {@endtemplate}
  factory RoutePath(String pathTemplate, {bool enableDeepLink = false}) {
    assert(
      !_pathParamsRegEx.hasMatch(pathTemplate),
      'pathTemplate must not contain any parameters',
    );
    return RoutePath._(
      pathTemplate,
      [],
      null,
      enableDeepLink: enableDeepLink,
    );
  }

  final GeneratePathArgs? generatePathArgs;

  @override
  Map<String, String> _generatePathArgs(Object? data) {
    return generatePathArgs?.call() ?? const {};
  }

  @override
  Object? _generateInitialData(
    Map<String, String> pathArgs,
  ) =>
      null;
}

/// Describes how a [DataStateRoute] integrates with platform (i.e. Navigator
/// 2.0) routing.
///
/// {@category Web Apps}
/// {@category Deep Linking}
class DataRoutePath<D> extends RoutePathInfo {
  DataRoutePath._(
    super.pathTemplate,
    super.parameters,
    this.generatePathArgs, {
    this.initialData,
    super.enableDeepLink,
  }) : assert(
          _pathTemplateRegEx.hasMatch(pathTemplate),
          "Invalid pathTemplate",
        );

  /// Constructs a [DataRoutePath] with a literal [pathTemplate].
  ///
  /// {@macro RoutePath.enableDeepLink}
  factory DataRoutePath(String pathTemplate, {bool enableDeepLink = false}) {
    assert(
        !_pathParamsRegEx.hasMatch(pathTemplate),
        'pathTemplate must not contain any parameters. Use the withParams '
        'factory to use a pathTemplate containing parameters.');
    return DataRoutePath._(
      pathTemplate,
      [],
      null,
      enableDeepLink: enableDeepLink,
    );
  }

  /// Constructs a parameterized [DataRoutePath].
  ///
  /// The [pathTemplate] should contain one or more segments prefixed with a `:`
  /// character, for example `user/:userId`.
  ///
  /// A [pathArgs] function must be provided that can generate values for the
  /// parameters in the path, based on the current data value of the data state.
  ///
  /// {@macro RoutePath.enableDeepLink}
  ///
  /// If deep linking is enabled, an [initialData] function must also be
  /// provided that can generate the initial data value of the data state, based
  /// on paremter values obtained from the URI.
  ///
  /// ```dart
  /// class UserData {
  ///   UserData(this.userId);
  ///   final int userId;
  /// }
  ///
  /// DataRoutePath<UserData>.parameterized(
  ///   'user/:userId',
  ///   pathArgs: (userData) =>
  ///     // Return a map containing a value for ech parameter in the template
  ///     { 'userId': '${userData.userId}'},
  ///   enableDeepLink: true,
  ///   initialData: (pathArgs) =>
  ///     // Return a UserData based in pathArgs that were parsed from a URI
  ///     UserData(int.parse(pathArgs['userId']!)),
  /// );
  /// ```
  factory DataRoutePath.parameterized(
    String pathTemplate, {
    required GenerateDataPathArgs<D> pathArgs,
    GenerateInitialData<D>? initialData,
    bool enableDeepLink = false,
  }) {
    var pathParameters =
        // Match 0 is :arg, Match 1 is arg (no colon prefix)
        _pathParamsRegEx.allMatches(pathTemplate).map((e) => e[1]!).toList();
    assert(
      pathParameters.isNotEmpty,
      'pathTemplate must contain at least one parameter',
    );
    assert(!enableDeepLink || initialData != null,
        'initialData is required if enableDeepLink is true');
    return DataRoutePath._(
      pathTemplate,
      pathParameters,
      pathArgs,
      initialData: initialData,
      enableDeepLink: enableDeepLink,
    );
  }

  /// The function called to obtain values for parameters in [pathTemplate],
  /// when [generateUriPath] is called.
  final GenerateDataPathArgs<D>? generatePathArgs;

  /// The function called when generating the initial value for a data state,
  /// when [matchUriPath] is called.
  final GenerateInitialData<D>? initialData;

  /// Creates a tree state filter that can be used to initialize state data when
  /// the entering the data state for this path, when following a deep link.
  InitializeStateDataFilter<D> createInitialDataFilter({Logger? log}) =>
      InitializeStateDataFilter<D>(log: log);

  @override
  Map<String, String> _generatePathArgs(Object? data) {
    assert(
        data == null || data is D,
        "Unexpected state data. Expected type $D, "
        "received type ${data.runtimeType}");
    return generatePathArgs?.call(data as D) ?? const {};
  }

  @override
  Object? _generateInitialData(
    Map<String, String> pathArgs,
  ) {
    return initialData?.call(pathArgs);
  }
}

/// The error thrown when a [RoutePathInfo] is misconfigured.
class RoutePathError extends Error {
  RoutePathError(this.message);
  final String message;
}
