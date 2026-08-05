import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final target = input.config.code.targetOS;
    if (target != OS.linux && target != OS.macOS && target != OS.windows) {
      return;
    }
    await CBuilder.library(
      name: 'tinyrack_pty',
      assetName: 'src/native_bindings.dart',
      sources: const <String>['src/tinyrack_pty.c'],
      includes: const <String>['src'],
      libraries: target == OS.linux ? const <String>['util'] : const <String>[],
      std: 'c11',
    ).run(input: input, output: output);
  });
}
