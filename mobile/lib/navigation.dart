import 'package:flutter/material.dart';

import 'design.dart';

class CamPahHeader extends StatelessWidget implements PreferredSizeWidget {
  const CamPahHeader(
      {super.key,
      required this.name,
      required this.onSignOut,
      required this.onNotifications});
  final String name;
  final Future<void> Function() onSignOut;
  final VoidCallback onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final initial = cleanName.isEmpty
        ? 'C'
        : String.fromCharCode(cleanName.runes.first).toUpperCase();
    return AppBar(
      toolbarHeight: 71,
      titleSpacing: 20,
      title: const Row(children: [
        CamPahMark(size: 40),
        SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CamPah',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4)),
          SizedBox(height: 2),
          Text('LEBIH PEDULI BUMI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: muted)),
        ])),
      ]),
      actions: [
        IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_none_rounded, size: 21)),
        const ThemeToggle(),
        Semantics(
            label: 'Profil $name',
            child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F1DB),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(initial,
                    style: const TextStyle(
                        color: forest,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)))),
        const SizedBox(width: 4),
        IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 21),
            tooltip: 'Keluar'),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor)),
    );
  }
}

class CamPahBottomNav extends StatelessWidget {
  const CamPahBottomNav(
      {super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final surface = Theme.of(context).colorScheme.surface;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 106,
        child: Stack(children: [
          Positioned.fill(
              top: 27,
              child: PhysicalShape(
                clipper: _NavBarClipper(),
                elevation: 6,
                shadowColor: const Color(0x330F392A),
                color: surface,
                child: Row(children: [
                  _NavItem(
                      label: 'Dashboard',
                      icon: Icons.grid_view_rounded,
                      selectedIcon: Icons.dashboard_rounded,
                      selected: selectedIndex == 0,
                      duration: duration,
                      onTap: () => onSelected(0)),
                  const SizedBox(width: 88),
                  _NavItem(
                      label: 'Riwayat',
                      icon: Icons.article_outlined,
                      selectedIcon: Icons.article_rounded,
                      selected: selectedIndex == 2,
                      duration: duration,
                      onTap: () => onSelected(2)),
                ]),
              )),
          Align(
              alignment: Alignment.topCenter,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Semantics(
                    label: 'Lapor',
                    button: true,
                    selected: selectedIndex == 1,
                    child: ExcludeSemantics(
                      child: AnimatedScale(
                        scale: selectedIndex == 1 ? 1.07 : 1,
                        duration: duration,
                        curve: Curves.easeOutBack,
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => onSelected(1),
                            customBorder: const CircleBorder(),
                            child: Ink(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: dark
                                        ? const [
                                            Color(0xFFBCEB7B),
                                            Color(0xFF79B969)
                                          ]
                                        : const [
                                            Color(0xFF397F58),
                                            Color(0xFF103D31)
                                          ]),
                                border: Border.all(color: surface, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                      color: (dark ? lime : forest)
                                          .withValues(alpha: .28),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: duration,
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                            opacity: animation, child: child)),
                                child: Icon(
                                    selectedIndex == 1
                                        ? Icons.add_a_photo_rounded
                                        : Icons.add_a_photo_outlined,
                                    key: ValueKey(selectedIndex == 1),
                                    size: 25,
                                    color: dark ? forest : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 5),
                ExcludeSemantics(
                    child: GestureDetector(
                        onTap: () => onSelected(1),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 3),
                            child: Text('Lapor',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: selectedIndex == 1
                                        ? Theme.of(context).colorScheme.primary
                                        : muted))))),
              ])),
        ]),
      ),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final center = size.width / 2;
    return Path()
      ..moveTo(24, 0)
      ..lineTo(center - 47, 0)
      ..cubicTo(center - 38, 0, center - 37, 29, center, 29)
      ..cubicTo(center + 37, 29, center + 38, 0, center + 47, 0)
      ..lineTo(size.width - 24, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 24)
      ..lineTo(size.width, size.height - 24)
      ..quadraticBezierTo(size.width, size.height, size.width - 24, size.height)
      ..lineTo(24, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 24)
      ..lineTo(0, 24)
      ..quadraticBezierTo(0, 0, 24, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.label,
      required this.icon,
      required this.selectedIcon,
      required this.selected,
      required this.duration,
      required this.onTap});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
          child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
              child: Center(
                  child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: 100,
            height: 61,
            decoration: BoxDecoration(
                color: selected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF304B3C)
                        : const Color(0xFFF0F7E9))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(19)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child)),
                  child: Icon(selected ? selectedIcon : icon,
                      key: ValueKey(selected),
                      size: 21,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF84988A))),
              const SizedBox(height: 5),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF7E9185),
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w700)),
            ]),
          ))),
        ),
      ));
}
