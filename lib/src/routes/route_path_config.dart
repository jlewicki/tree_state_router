import 'package:logging/logging.dart';
import 'package:tree_state_router/tree_state_router.dart';

typedef GeneratePathArgs = Map<String, String> Function();
typedef GenerateDataPathArgs<D> = Map<String, String> Function(D data);
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
final _pathTemplateRegEx = RegExp(r'^[^\\\/]+[^\\]*[^\\\/]+$');

// Identifies the parameters in a path like user/:userId/address/:addressId
final _pathParamsRegEx = RegExp(r':(\w+)');
//final _pathArgsRegEx = RegExp(r':(\w+)(\((?:\\.|[^\\()])+\))?');

sealed class RoutePathConfig {
  RoutePathConfig(
    this.pathTemplate,
    this.parameters, {
    this.enableDeepLink = false,
  }) : assert(pathTemplate.isNotEmpty, 'pathTemplate cannot be empty');

  /// The path segment template to use for the associated route, when a routing
  /// URI needs to be generated.
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

  late final String uriPathPattern = _replaceTemplateParameters((paramName) {
    // Replace the :paramName token with a named capture group that can match
    // capture the parameter value when it occurs within a URI path
    return '(?<$paramName>[^/]+)';
  });

  late final _uriPathRegEx = RegExp('^/$uriPathPattern', caseSensitive: false);

  /// Generates a path appropriate for a URI representing all the routes in
  /// this route path.
  ///
  /// The state [data] for the data state associated with this route path is
  /// provided, or `null` if the state is not a data state.
  String generateUriPath(dynamic data) {
    var pathArgs = _generatePathArgs(data);
    // TODO: find a way to replace parms without repeatedly running regexp
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

  /// Attempts to match the [uriPath] against the routes in this route path.
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

/// Describes how a route integrates with platform (i.e. Navigator 2.0) routing.
class RoutePath extends RoutePathConfig {
  RoutePath._(
    super.pathTemplate,
    super.parameters,
    this.generatePathArgs, {
    super.enableDeepLink,
  }) : assert(
          _pathTemplateRegEx.hasMatch(pathTemplate),
          'Invalid pathTemplate',
        );

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

class DataRoutePath<D> extends RoutePathConfig {
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

  factory DataRoutePath.withParams(
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

  final GenerateDataPathArgs<D>? generatePathArgs;
  final GenerateInitialData<D>? initialData;
  InitializeStateDataFilter<D> createFilter({Logger? log}) =>
      InitializeStateDataFilter<D>(log: log);

  @override
  Map<String, String> _generatePathArgs(Object? data) {
    assert(
        data == null || data is D,
        "Unexpoected state data. Expected type $D, "
        "received type ${data!.runtimeType}");
    return generatePathArgs?.call(data as D) ?? const {};
  }

  @override
  Object? _generateInitialData(
    Map<String, String> pathArgs,
  ) {
    return initialData?.call(pathArgs);
  }
}

class RoutePathError extends Error {
  RoutePathError(this.message);
  final String message;
}
