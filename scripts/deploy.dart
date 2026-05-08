#!/usr/bin/env dart
// deploy.dart — script de deploy interativo para Vida Ativa
//
// Uso:
//   dart run scripts/deploy.dart                  → modo interativo
//   dart run scripts/deploy.dart staging          → staging, pergunta o que deploiar
//   dart run scripts/deploy.dart prod             → prod, pergunta o que deploiar
//   dart run scripts/deploy.dart staging hosting  → staging, só hosting
//   dart run scripts/deploy.dart prod all         → prod, deploy completo

import 'dart:io';

// ─────────────────────────────────────────────
// Constantes
// ─────────────────────────────────────────────

const _sentryDsn =
    'https://79d964a02371cac9a464590c7d4e7592@o4511112494710784.ingest.us.sentry.io/4511112496414720';

const _vapidKeys = {
  'staging': 'BKljao1LlvttrjI6nbvvVRfRD4VeZmMp32uyEaDqU3u6XoGIVkd9AdrnhCl_9-Q1rm2AHHMu9CUyrOvtzO5xQUw',
  'prod':    'BE4IVHDfXnkE9o2xxSfYWpKxggsOlYKDI14_VW0wAEj_mWIx-K6lSDKQoLBbzFdgI8Ajrsv8FCen99oI-ST6qB4',
};

const _firebaseProject = {
  'staging': 'staging',  // alias em .firebaserc
  'prod':    'default',  // alias em .firebaserc
};

// ─────────────────────────────────────────────
// Helpers de I/O
// ─────────────────────────────────────────────

String _cyan(String s)  => '\x1B[36m$s\x1B[0m';
String _green(String s) => '\x1B[32m$s\x1B[0m';
String _red(String s)   => '\x1B[31m$s\x1B[0m';
String _bold(String s)  => '\x1B[1m$s\x1B[0m';
String _dim(String s)   => '\x1B[2m$s\x1B[0m';

void log(String msg)    => stdout.writeln(msg);
void step(String msg)   => stdout.writeln('\n${_bold(_cyan("▶ $msg"))}');
void ok(String msg)     => stdout.writeln(_green('✓ $msg'));
void err(String msg)    { stderr.writeln(_red('✗ $msg')); exit(1); }

String ask(String prompt, {String? defaultValue}) {
  final hint = defaultValue != null ? _dim(' [$defaultValue]') : '';
  stdout.write('$prompt$hint: ');
  final line = stdin.readLineSync()?.trim() ?? '';
  return line.isEmpty && defaultValue != null ? defaultValue : line;
}

bool confirm(String prompt, {bool defaultYes = true}) {
  final hint = defaultYes ? '[Y/n]' : '[y/N]';
  stdout.write('$prompt $hint: ');
  final line = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (line.isEmpty) return defaultYes;
  return line == 'y' || line == 'yes' || line == 's' || line == 'sim';
}

// ─────────────────────────────────────────────
// Execução de processos
// ─────────────────────────────────────────────

Future<void> run(String cmd, List<String> args, {String? workingDir}) async {
  log(_dim('  \$ $cmd ${args.join(' ')}'));
  final result = await Process.run(
    cmd, args,
    workingDirectory: workingDir ?? Directory.current.path,
    runInShell: true,
  );
  if (result.stdout.toString().isNotEmpty) stdout.write(result.stdout);
  if (result.stderr.toString().isNotEmpty) stderr.write(result.stderr);
  if (result.exitCode != 0) err('Falhou com exit code ${result.exitCode}');
}

Future<void> runInherit(String cmd, List<String> args, {String? workingDir}) async {
  log(_dim('  \$ $cmd ${args.join(' ')}'));
  final process = await Process.start(
    cmd, args,
    workingDirectory: workingDir ?? Directory.current.path,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) err('Falhou com exit code $exitCode');
}

// ─────────────────────────────────────────────
// Versão
// ─────────────────────────────────────────────

({String semver, int build}) _parseVersion(String raw) {
  final parts = raw.trim().split('+');
  return (semver: parts[0], build: parts.length > 1 ? int.parse(parts[1]) : 0);
}

String _readCurrentVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspec);
  if (match == null) err('Versão não encontrada em pubspec.yaml');
  return match!.group(1)!.trim();
}

String _promptVersion(String current) {
  final v = _parseVersion(current);
  final suggested = '${v.semver}+${v.build + 1}';
  log('  Versão atual: ${_bold(current)}');
  log('  Sugestão     : ${_bold(suggested)} ${_dim("(bump build number)")}');
  final input = ask('  Nova versão', defaultValue: suggested);
  return input;
}

void _writeVersion(String newVersion) {
  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();
  final updated = content.replaceFirstMapped(
    RegExp(r'^(version:\s*)(.+)$', multiLine: true),
    (m) => '${m.group(1)}$newVersion',
  );
  pubspecFile.writeAsStringSync(updated);
  ok('pubspec.yaml → versão $newVersion');
}

// ─────────────────────────────────────────────
// Histórico no DEPLOY.md
// ─────────────────────────────────────────────

void _appendDeployHistory(String version, String env, String description) {
  final deployFile = File('DEPLOY.md');
  if (!deployFile.existsSync()) return;

  final now = DateTime.now();
  final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  final row = '| $version${' ' * (9 - version.length)} | $date | ${env.padRight(8)} | $description |';

  final content = deployFile.readAsStringSync();
  final updated = content.replaceFirstMapped(
    RegExp(r'(\| Versão.*\n\|[-|]+\n)([\s\S]*?)(\n\s*$)', multiLine: true),
    (m) => '${m.group(1)}$row\n${m.group(2)}${m.group(3)}',
  );

  if (updated != content) {
    deployFile.writeAsStringSync(updated);
    ok('DEPLOY.md → histórico atualizado');
  }
}

// ─────────────────────────────────────────────
// Menu de seleção de target
// ─────────────────────────────────────────────

String _chooseTarget() {
  log('');
  log('  O que deploiar?');
  log('  1) Só hosting  ${_dim("(frontend)")}');
  log('  2) Só functions');
  log('  3) Só firestore ${_dim("(rules + indexes)")}');
  log('  4) Completo     ${_dim("(hosting + functions + firestore)")}');
  final input = ask('  Opção', defaultValue: '1');
  return switch (input.trim()) {
    '1' => 'hosting',
    '2' => 'functions',
    '3' => 'firestore',
    '4' => 'all',
    _   => input.toLowerCase(),
  };
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────

Future<void> main(List<String> argv) async {
  // Garante que estamos na raiz do projeto
  if (!File('pubspec.yaml').existsSync()) {
    err('Execute a partir da raiz do projeto (onde está pubspec.yaml)');
  }

  log('');
  log(_bold('══════════════════════════════════'));
  log(_bold('  Deploy — Vida Ativa             '));
  log(_bold('══════════════════════════════════'));

  // ── 1. Ambiente ──────────────────────────────
  String env;
  if (argv.isNotEmpty && (argv[0] == 'staging' || argv[0] == 'prod')) {
    env = argv[0];
  } else {
    log('');
    log('  Ambiente:');
    log('  1) staging');
    log('  2) prod');
    final input = ask('  Opção', defaultValue: '1');
    env = input == '2' ? 'prod' : 'staging';
  }
  log('  Ambiente: ${_bold(env)}');

  // ── 2. Versão ────────────────────────────────
  step('Versão');
  final currentVersion = _readCurrentVersion();
  final newVersion = _promptVersion(currentVersion);
  _writeVersion(newVersion);

  // ── 3. Service Worker ────────────────────────
  step('Gerando Service Worker para $env');
  await run('node', ['scripts/generate-sw.js', env]);
  ok('web/firebase-messaging-sw.js gerado');

  // ── 4. Flutter build ─────────────────────────
  step('Flutter build web [$env]');
  final buildArgs = [
    'build', 'web', '--release',
    '--dart-define=ENV=$env',
    '--dart-define=VAPID_PUBLIC_KEY=${_vapidKeys[env]}',
    if (env == 'prod') '--dart-define=SENTRY_DSN=$_sentryDsn',
  ];
  await runInherit('flutter', buildArgs);
  ok('Build concluído');

  // ── 5. Target de deploy ──────────────────────
  step('Target de deploy');
  String target;
  if (argv.length >= 2) {
    target = argv[1].toLowerCase();
  } else {
    target = _chooseTarget();
  }

  // ── 6. Firebase deploy ───────────────────────
  step('Firebase deploy [$env / $target]');
  final project = _firebaseProject[env]!;
  final deployArgs = [
    'deploy',
    '--project', project,
    if (target != 'all') ...['--only', target],
  ];
  await runInherit('firebase', deployArgs);
  ok('Deploy concluído!');

  // ── 7. Histórico ─────────────────────────────
  step('Atualizando histórico');
  final description = ask('  Descrição para o histórico', defaultValue: 'deploy $env');
  _appendDeployHistory(newVersion, env, description);

  log('');
  log(_bold(_green('══════════════════════════════════')));
  log(_bold(_green('  Deploy finalizado com sucesso!  ')));
  log(_bold(_green('══════════════════════════════════')));
  log('');
}
