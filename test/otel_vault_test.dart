// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_vault/otel_vault.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_vault-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('GET kv path records CLIENT span', () async {
    await tracedVault<String>(
      method: 'GET',
      mountPath: 'kv/data/app/db',
      namespace: 'team-a',
      clusterAddress: 'https://vault.acme.com',
      invoke: () async => 'secret',
    );
    final a = attrsOf(spans.findSpanByName('vault GET kv/data/app/db')!);
    expect(a['vault.method'], 'GET');
    expect(a['vault.path'], 'kv/data/app/db');
    expect(a['http.request.method'], 'GET');
    expect(a['vault.namespace'], 'team-a');
    expect(a['vault.cluster.address'], 'https://vault.acme.com');
  });

  test('LIST maps to GET in http.request.method', () async {
    await tracedVault<String>(
      method: 'LIST',
      mountPath: 'kv/metadata/app',
      invoke: () async => 'keys',
    );
    final a = attrsOf(spans.findSpanByName('vault LIST kv/metadata/app')!);
    expect(a['vault.method'], 'LIST');
    expect(a['http.request.method'], 'GET');
  });

  test('suppression skips spans', () async {
    await runWithoutVaultInstrumentationAsync(() async {
      await tracedVault<String>(
        method: 'GET',
        mountPath: 'kv/data/x',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('vault '), isEmpty);
  });
}
