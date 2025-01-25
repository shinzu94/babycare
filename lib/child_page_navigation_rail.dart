import 'package:babycare/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class ChildPageNavigationRail extends StatefulWidget {
  String? id;
  ChildPageNavigationRail({super.key, required this.id});

  @override
  State<ChildPageNavigationRail> createState() => _ChildPageNavigationRailState(id: this.id);
}

class _ChildPageNavigationRailState extends State<ChildPageNavigationRail> {
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;
  String? id;

  _ChildPageNavigationRailState({required this.id});

  @override
  Widget build(BuildContext context) {
    bool haveId = id != null;
    print("build f");
    print(id);
    print(haveId);
    final goRouter = GoRouter.of(context);
    final currentRoute = goRouter.routerDelegate.currentConfiguration!.fullPath;

    switch (currentRoute) {
      case Routes.child_diaper_change:
        _selectedIndex = 1;
        break;
      case Routes.child:
      case Routes.newChild:
      default: _selectedIndex = 0;
        break;
    }

    return NavigationRail(
          selectedIndex: _selectedIndex,
          groupAlignment: groupAlignment,
          onDestinationSelected: (int index) {
            setState(() {
              print(index);
              print(id);
              switch (index) {
                case 0: context.go(Routes.child.replaceFirst(":id", id!));
                break;
                case 1: context.go(Routes.child_diaper_change.replaceFirst(":id", id!));
                break;
              }
              _selectedIndex = index;
            });
          },
          labelType: labelType,
          leading: showLeading
              ? FloatingActionButton(
            elevation: 0,
            onPressed: () {
              // Add your onPressed code here!
            },
            child: const Icon(Icons.add),
          )
              : const SizedBox(),
          trailing: showTrailing
              ? IconButton(
            onPressed: () {
              // Add your onPressed code here!
            },
            icon: const Icon(Icons.more_horiz_rounded),
          )
              : const SizedBox(),
          destinations: <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.child_care),
              selectedIcon: Icon(Icons.child_care),
              label: Text('Profil'),
              disabled: !haveId
            ),
            NavigationRailDestination(
              icon: Icon(Icons.baby_changing_station_outlined),
              selectedIcon: Icon(Icons.baby_changing_station),
              label: Text('Przewijanie'),
              disabled: !haveId
            ),
          ],
    );
  }
}
