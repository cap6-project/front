import 'package:flutter/material.dart';

enum DrawerMenuAction {
  placeholder,
  chat,
  settings,
}

/// Drawer 메뉴 항목 모델
///
/// 역할:
/// - 메뉴 표시 정보 보관
/// - 메뉴 선택 시 실행할 action 구분
/// - title 문자열 비교 제거
class DrawerMenuItem {
  final String title;
  final IconData icon;
  final DrawerMenuAction action;

  const DrawerMenuItem({
    required this.title,
    required this.icon,
    required this.action,
  });
}