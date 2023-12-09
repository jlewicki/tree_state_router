import 'package:flutter/material.dart';
import 'package:tree_state_router/src/pages/pages.dart';

class MaterialTreeStatePage extends MaterialPage<void> {
  const MaterialTreeStatePage({super.key, required super.child});
}

PageBuilder materialPageBuilder = (buildFor, content) => MaterialTreeStatePage(child: content);
