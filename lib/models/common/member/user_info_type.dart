import 'package:flutter/material.dart' show Alignment;

enum UserInfoType {
  dyn('动态', .centerLeft),
  follow('关注', .center),
  fan('粉丝', .centerRight),
  ;

  final String title;
  final Alignment alignment;

  const UserInfoType(this.title, this.alignment);
}
