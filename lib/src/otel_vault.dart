// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_vault_suppression.dart';

const _tracerName = 'dartastic_otel_libs_vault';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a HashiCorp Vault API call in a CLIENT span. [method] is
/// the HTTP verb (`GET`, `POST`, `LIST`, `DELETE`); [mountPath] is
/// the mount + path (e.g. `kv/data/app/db`, `auth/approle/login`).
/// Never records the secret value itself.
Future<T> tracedVault<T>({
  required String method,
  required String mountPath,
  required Future<T> Function() invoke,
  String? namespace,
  String? clusterAddress,
}) async {
  if (vaultInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'vault.method': method,
    'vault.path': mountPath,
    'http.request.method': method == 'LIST' ? 'GET' : method,
  };
  if (namespace != null) m['vault.namespace'] = namespace;
  if (clusterAddress != null) m['vault.cluster.address'] = clusterAddress;

  final span = _tracer().startSpan(
    'vault $method $mountPath',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
