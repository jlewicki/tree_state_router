import 'package:flutter/material.dart';
import 'package:tree_state_router/src/pages/pages.dart';

class MaterialTreeStatePage extends MaterialPage<void> {
  const MaterialTreeStatePage(Widget child)
      : super(
          child: child,
        );
}

PageBuilder materialPageBuilder = (_, content) => MaterialTreeStatePage(content);
