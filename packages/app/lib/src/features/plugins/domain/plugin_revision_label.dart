/// Characters of a revision digest that identify it on sight.
///
/// A plugin revision is a full sha256 digest. Whole, it is wider as a
/// monospace chip than the settings column is at any window width, so the row
/// that carried it squeezed its own label down to one character per line and
/// still overflowed. Its leading characters name the revision the same way a
/// short commit hash does.
const pluginRevisionLabelCharacters = 12;

/// The characters of [hash] that a settings row shows.
///
/// A digest shorter than the label length is already its own label.
String pluginRevisionLabel(String hash) =>
    hash.length <= pluginRevisionLabelCharacters
    ? hash
    : hash.substring(0, pluginRevisionLabelCharacters);
