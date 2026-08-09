// Daemon discovery on the local machine. Kept out of the client barrel
// because this library imports dart:io, which cannot compile to JavaScript,
// and the barrel must stay usable on the web.
export 'src/local_daemon.dart';
