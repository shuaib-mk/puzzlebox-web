import 'dart:js_interop';

@JS('eval')
external void _nativeEvalJS(JSString code);

void evalJS(String code) {
  try {
    _nativeEvalJS(code.toJS);
  } catch (_) {}
}
