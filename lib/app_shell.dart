import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/pwa/ios_install_detector.dart';
import 'core/utils/snack_helper.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    if (isIosInstallBannerNeeded()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SnackHelper.info(
          context,
          'Instale o app: toque em Compartilhar › Adicionar à Tela de Início',
          duration: const Duration(seconds: 15),
          action: SnackBarAction(
            label: 'X',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_volleyball_outlined),
            selectedIcon: Icon(Icons.sports_volleyball),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
