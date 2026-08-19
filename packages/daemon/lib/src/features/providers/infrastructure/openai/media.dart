/// Image media types every transport in this package inlines as a data URL.
///
/// Not one vendor's list: this is the common web image set, and whether a
/// given turn may use it is decided by the selected model's image capability
/// rather than by the endpoint.
const Set<String> inlineImageMediaTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
};
