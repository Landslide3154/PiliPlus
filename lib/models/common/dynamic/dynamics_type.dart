import 'package:PiliPlus/models/common/enum_with_label.dart';

enum DynamicsTabType implements EnumWithLabel {
  all('全部'),
  video('视频'),
  pgc('番剧'),
  up('UP'),
  ;

  @override
  final String label;
  const DynamicsTabType(this.label);
}
