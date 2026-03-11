import 'dart:js' as js;

String webEval(String script) {
  return js.context.callMethod('eval', [script]).toString();
}