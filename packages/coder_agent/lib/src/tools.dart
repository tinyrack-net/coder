/// The tools compiled into the agent, one library each.
///
/// A tool owns its schema, its limits, and its execution in a single file, so
/// adding one means adding a file rather than editing a shared list. This
/// library re-exports them for consumers that want the whole set.
library;

export 'package:coder_agent/src/tools/apply_patch.dart';
export 'package:coder_agent/src/tools/ask_user.dart';
export 'package:coder_agent/src/tools/attach_file.dart';
export 'package:coder_agent/src/tools/glob.dart';
export 'package:coder_agent/src/tools/list_directory.dart';
export 'package:coder_agent/src/tools/patch/unified_diff.dart';
export 'package:coder_agent/src/tools/read_attachment.dart';
export 'package:coder_agent/src/tools/read_file.dart';
export 'package:coder_agent/src/tools/search_text.dart';
export 'package:coder_agent/src/tools/tool_support.dart';
export 'package:coder_agent/src/tools/update_plan.dart';
export 'package:coder_agent/src/tools/view_image.dart';
