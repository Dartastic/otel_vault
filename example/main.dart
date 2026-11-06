// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_vault/otel_vault.dart';

/// Traces HashiCorp Vault calls with OpenTelemetry.
///
/// `otel_vault` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each HashiCorp Vault call in
/// [tracedVault]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'vault-example');

  // Wraps a HashiCorp Vault API call in a CLIENT span.
  final vaultId = await tracedVault<String>(
    method: 'GET',
    mountPath: '/v1/orders',
    namespace: 'example',
    clusterAddress: 'example',
    invoke: () async {
      // Make the HashiCorp Vault call here, then report what it returned.
      return 'vault_8f3a2c';
    },
  );
  OTelLog.info('tracedVault kv/data/app/db returned $vaultId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutVaultInstrumentationAsync.
  await runWithoutVaultInstrumentationAsync(
    () => tracedVault<String>(
      method: 'GET',
      mountPath: '/v1/orders',
      namespace: 'example',
      clusterAddress: 'example',
      invoke: () async {
        return 'vault_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
