{pkgs}: {
  deps = [
    pkgs.jdk17_headless
    pkgs.jdk17
    pkgs.wget
    pkgs.unzip
    pkgs.android-tools
    pkgs.flutter
  ];
}
