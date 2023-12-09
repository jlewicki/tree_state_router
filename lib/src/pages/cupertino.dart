import 'package:flutter/cupertino.dart';
import 'package:tree_state_router/src/pages/pages.dart';

class CupertinoTreeStatePage extends CupertinoPage<void> {
  const CupertinoTreeStatePage(Widget child)
      : super(
          child: child,
        );
}

PageBuilder cupertinoPageBuilder = (_, content) => CupertinoTreeStatePage(content);
