/// Matches a `{{name}}` placeholder in a prompt template.
final RegExp _placeholder = RegExp(r'\{\{(\w+)\}\}');

/// Substitutes `{{name}}` placeholders in [template] from [variables].
///
/// A placeholder no variable supplies renders as nothing rather than as its
/// own literal text: a template whose optional section is unset must not leak
/// the placeholder into the model's instructions.
String renderPromptTemplate(String template, Map<String, String> variables) =>
    template.replaceAllMapped(
      _placeholder,
      (match) => variables[match.group(1)] ?? '',
    );
