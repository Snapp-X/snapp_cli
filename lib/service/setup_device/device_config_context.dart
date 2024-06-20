import 'dart:io';

import 'package:snapp_cli/configs/embedder.dart';
import 'package:snapp_cli/utils/common.dart';

class DeviceConfigContext {
  const DeviceConfigContext({
    this.id,
    this.label,
    this.targetIp,
    this.username,
    this.remoteHasSshConnection = false,
    this.appExecuterPath,
    this.embedder,
  });

  static const DeviceConfigContext empty = DeviceConfigContext();

  final String? id;
  final String? label;
  final InternetAddress? targetIp;
  final String? username;
  final bool remoteHasSshConnection;
  final String? appExecuterPath;
  final FlutterEmbedder? embedder;

  bool? get ipv6 => targetIp?.isIpv6;

  InternetAddress? get loopbackIp => ipv6 == null
      ? null
      : ipv6!
          ? InternetAddress.loopbackIPv6
          : InternetAddress.loopbackIPv4;

  String? get sshTarget => targetIp == null || username == null
      ? null
      : targetIp!.sshTarget(username!);

  String? get formattedLoopbackIp => loopbackIp == null
      ? null
      : ipv6 == true
          ? '[${loopbackIp!.address}]'
          : loopbackIp!.address;

  String? get sdkName => embedder?.sdkName;

  String get formattedLabel {
    if (label == null || embedder == null) {
      return '';
    }

    return '$label-[${embedder!.label}]';
  }

  DeviceConfigContext copyWith({
    String? id,
    String? label,
    InternetAddress? targetIp,
    String? username,
    bool? remoteHasSshConnection,
    String? appExecuterPath,
    FlutterEmbedder? embedder,
  }) {
    return DeviceConfigContext(
      id: id ?? this.id,
      label: label ?? this.label,
      targetIp: targetIp ?? this.targetIp,
      username: username ?? this.username,
      remoteHasSshConnection:
          remoteHasSshConnection ?? this.remoteHasSshConnection,
      appExecuterPath: appExecuterPath ?? this.appExecuterPath,
      embedder: embedder ?? this.embedder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceConfigContext &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          targetIp == other.targetIp &&
          username == other.username &&
          remoteHasSshConnection == other.remoteHasSshConnection &&
          appExecuterPath == other.appExecuterPath &&
          embedder == other.embedder;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      targetIp.hashCode ^
      username.hashCode ^
      remoteHasSshConnection.hashCode ^
      appExecuterPath.hashCode ^
      embedder.hashCode;

  @override
  String toString() {
    return 'DeviceConfigContext{id: $id, label: $label, targetIp: $targetIp, username: $username, remoteHasSshConnection: $remoteHasSshConnection, appExecuter: $appExecuterPath, embedder: $embedder}';
  }
}
