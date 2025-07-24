// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:io';

import 'proxy_manager_platform_interface.dart';
import 'package:path/path.dart' as path;

enum ProxyTypes { http, https, socks }

class ProxyManager {
  /// get platform version
  Future<String?> getPlatformVersion() {
    return ProxyManagerPlatform.instance.getPlatformVersion();
  }

  /// set system proxy
  Future<void> setAsSystemProxy(ProxyTypes types, String url, int port) async {
    switch (Platform.operatingSystem) {
      case "windows":
        await _setAsSystemProxyWindows(types, url, port);
        break;
      case "linux":
        _setAsSystemProxyLinux(types, url, port);
        break;
      case "macos":
        await _setAsSystemProxyMacos(types, url, port);
        break;
    }
  }

  Future<List<String>> _getNetworkDeviceListMacos() async {
    final resp = await Process.run(
        "/usr/sbin/networksetup", ["-listallnetworkservices"]);
    final lines = resp.stdout.toString().split("\n");
    lines.removeWhere((element) => element.contains("*"));
    return lines;
  }

  Future<void> _setAsSystemProxyMacos(
      ProxyTypes type, String url, int port) async {
    final devices = await _getNetworkDeviceListMacos();
    for (final dev in devices) {
      switch (type) {
        case ProxyTypes.http:
          await Process.run(
              "/usr/sbin/networksetup", ["-setwebproxystate", dev, "on"]);
          await Process.run(
              "/usr/sbin/networksetup", ["-setwebproxy", dev, url, "$port"]);
          break;
        case ProxyTypes.https:
          await Process.run(
              "/usr/sbin/networksetup", ["-setsecurewebproxystate", dev, "on"]);
          await Process.run("/usr/sbin/networksetup",
              ["-setsecurewebproxy", dev, url, "$port"]);
          break;
        case ProxyTypes.socks:
          await Process.run("/usr/sbin/networksetup",
              ["-setsocksfirewallproxystate", dev, "on"]);
          await Process.run("/usr/sbin/networksetup",
              ["-setsocksfirewallproxy", dev, url, "$port"]);
          break;
      }
    }
  }

  Future<void> _cleanSystemProxyMacos() async {
    final devices = await _getNetworkDeviceListMacos();
    for (final dev in devices) {
      await Future.wait([
        Process.run(
            "/usr/sbin/networksetup", ["-setautoproxystate", dev, "off"]),
        Process.run(
            "/usr/sbin/networksetup", ["-setwebproxystate", dev, "off"]),
        Process.run(
            "/usr/sbin/networksetup", ["-setsecurewebproxystate", dev, "off"]),
        Process.run("/usr/sbin/networksetup",
            ["-setsocksfirewallproxystate", dev, "off"]),
      ]);

      // Clear proxy bypass domains
      await Process.run(
          "/usr/sbin/networksetup", ["-setproxybypassdomains", dev, "Empty"]);
    }
  }

  Future<void> _setAsSystemProxyWindows(
      ProxyTypes types, String url, int port) async {
    await ProxyManagerPlatform.instance.setSystemProxy(types, url, port);
  }

  void _setAsSystemProxyLinux(ProxyTypes types, String url, int port) {
    final homeDir = Platform.environment['HOME']!;
    final configDir = path.join(homeDir, ".config");
    final cmdList = List<List<String>>.empty(growable: true);
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    final isKDE = desktop == "KDE";
    // gsetting
    cmdList
        .add(["gsettings", "set", "org.gnome.system.proxy", "mode", "manual"]);
    cmdList.add([
      "gsettings",
      "set",
      "org.gnome.system.proxy.${types.name}",
      "host",
      "$url"
    ]);
    cmdList.add([
      "gsettings",
      "set",
      "org.gnome.system.proxy.${types.name}",
      "port",
      "$port"
    ]);
    // kde
    if (isKDE) {
      cmdList.add([
        "kwriteconfig5",
        "--file",
        "$configDir/kioslaverc",
        "--group",
        "Proxy Settings",
        "--key",
        "ProxyType",
        "1"
      ]);
      cmdList.add([
        "kwriteconfig5",
        "--file",
        "$configDir/kioslaverc",
        "--group",
        "Proxy Settings",
        "--key",
        "${types.name}Proxy",
        "${types.name}://$url:$port"
      ]);
    }
    for (final cmd in cmdList) {
      final res = Process.runSync(cmd[0], cmd.sublist(1), runInShell: true);
      print('cmd: $cmd returns ${res.exitCode}');
    }
  }

  Future<void> setProxyBypassDomains(List<String> domains) async {
    switch (Platform.operatingSystem) {
      case "linux":
        throw UnsupportedError(
            "setProxyBypassDomains is not supported on Linux");
      case "windows":
        await ProxyManagerPlatform.instance.setProxyBypassDomains(domains);
        break;
      case "macos":
        final devices = await _getNetworkDeviceListMacos();
        for (final dev in devices) {
          await Process.run("/usr/sbin/networksetup",
              ["-setproxybypassdomains", dev, ...domains]);
        }
        break;
    }
  }

  /// clean system proxy
  Future<void> cleanSystemProxy() async {
    switch (Platform.operatingSystem) {
      case "linux":
        _cleanSystemProxyLinux();
        break;
      case "windows":
        await _cleanSystemProxyWindows();
        break;
      case "macos":
        await _cleanSystemProxyMacos();
    }
  }

  /// set proxy bypass local addresses (Windows only)
  Future<void> setProxyBypassLocal(bool bypass) async {
    if (Platform.operatingSystem == "windows") {
      await ProxyManagerPlatform.instance.setProxyBypassLocal(bypass);
    }
    switch (Platform.operatingSystem) {
      case "linux":
        throw UnsupportedError("setProxyBypassLocal is not supported on Linux");
      case "macos":
        final bypassDomains = [
          "192.168.0.0/16",
          "172.16.0.0/12",
          "10.0.0.0/8",
          "169.254.0.0/16",
          "224.0.0.0/4",
          "fe80::/10",
          "ff00::/8",
          "100.64.0.0/10",
          "192.18.0.0/15",
          "*.local"
        ];
        await setProxyBypassDomains(bypass ? bypassDomains : []);
        break;
      case "windows":
        await ProxyManagerPlatform.instance.setProxyBypassLocal(bypass);
        break;
    }
  }

  Future<void> _cleanSystemProxyWindows() async {
    await ProxyManagerPlatform.instance.cleanSystemProxy();
    // Clear bypass domains by setting empty list
    await ProxyManagerPlatform.instance.setProxyBypassDomains([]);
  }

  void _cleanSystemProxyLinux() {
    final homeDir = Platform.environment['HOME']!;
    final configDir = path.join(homeDir, ".config/");
    final cmdList = List<List<String>>.empty(growable: true);
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    final isKDE = desktop == "KDE";
    // gsetting
    cmdList.add(["gsettings", "set", "org.gnome.system.proxy", "mode", "none"]);
    if (isKDE) {
      cmdList.add([
        "kwriteconfig5",
        "--file",
        "$configDir/kioslaverc",
        "--group",
        "Proxy Settings",
        "--key",
        "ProxyType",
        "0"
      ]);
    }
    for (final cmd in cmdList) {
      final res = Process.runSync(cmd[0], cmd.sublist(1));
      print('cmd: $cmd returns ${res.exitCode}');
    }
  }
}
