Apply one patch document atomically inside the workspace. Send the whole document as the `patch` string; it is plain text, not nested JSON.

Use this envelope:

```text
*** Begin Patch
*** Add File: path
+new line
*** Update File: path
@@ optional context
-old line
+new line
*** Move to: new-path
*** Delete File: path
*** End Patch
```

Every operation starts with `*** Add File:`, `*** Update File:`, or `*** Delete File:`. An update may include `*** Move to:`. Added lines, including all lines in a new file, start with `+`; removed lines start with `-`; unchanged context lines start with one space. Paths must be workspace-relative. Read a file before patching it so context matches exactly. The whole document succeeds or fails atomically.
