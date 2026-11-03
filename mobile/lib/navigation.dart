import 'package:flutter/material.dart';

import 'design.dart';

class CamPahHeader extends StatelessWidget implements PreferredSizeWidget {
  const CamPahHeader({super.key, required this.name, required this.onSignOut});
  final String name;
  final Future<void> Function() onSignOut;

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
          child: Container(height: 1, color: const Color(0xFFE6ECE3))),
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFE4EDE3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x140F392A), blurRadius: 24, offset: Offset(0, 6))
          ],
        ),
        child: LayoutBuilder(
            builder: (context, constraints) => Stack(children: [
                  Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedAlign(
                        alignment: Alignment(selectedIndex.toDouble() - 1, 0),
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        child: Container(
                            width: (constraints.maxWidth - 12) / 3,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0F7E9),
                                borderRadius: BorderRadius.circular(19))),
                      )),
                  Row(children: [
                    _NavItem(
                        label: 'Dashboard',
                        icon: Icons.grid_view_rounded,
                        selectedIcon: Icons.dashboard_rounded,
                        selected: selectedIndex == 0,
                        duration: duration,
                        onTap: () => onSelected(0)),
                    _NavItem(
                        label: 'Lapor',
                        icon: Icons.add_a_photo_outlined,
                        selectedIcon: Icons.add_a_photo_rounded,
                        selected: selectedIndex == 1,
                        duration: duration,
                        onTap: () => onSelected(1),
                        camera: true),
                    _NavItem(
                        label: 'Riwayat',
                        icon: Icons.article_outlined,
                        selectedIcon: Icons.article_rounded,
                        selected: selectedIndex == 2,
                        duration: duration,
                        onTap: () => onSelected(2)),
                  ]),
                ])),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.label,
      required this.icon,
      required this.selectedIcon,
      required this.selected,
      required this.duration,
      required this.onTap,
      this.camera = false});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool camera;
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
          borderRadius: BorderRadius.circular(19),
          child: ExcludeSemantics(
              child: SizedBox.expand(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: duration,
                    width: camera ? 37 : 28,
                    height: camera ? 37 : 28,
                    decoration: camera
                        ? BoxDecoration(
                            color: selected ? forest : const Color(0xFF2B5E46),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                        color: Color(0x30285338),
                                        blurRadius: 9,
                                        offset: Offset(0, 3))
                                  ]
                                : [])
                        : null,
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child:
                              ScaleTransition(scale: animation, child: child)),
                      child: Icon(selected ? selectedIcon : icon,
                          key: ValueKey(selected),
                          size: camera ? 19 : 21,
                          color: camera
                              ? Colors.white
                              : selected
                                  ? forest
                                  : const Color(0xFF84988A)),
                    ),
                  ),
                ),
                SizedBox(height: camera ? 2 : 5),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selected ? forest : const Color(0xFF7E9185),
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700)),
              ]))),
        ),
      ));
}
