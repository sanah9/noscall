# Vendored CDK Dart

This package is based on `cashubtc/cdk-dart` v0.17.1 at commit
`98e90108f8ecc89cf0ff6a0d196ebcd7ca4c5a4e`.

## Local patches

1. Keep `rust-toolchain.toml` beside `rust/Cargo.toml`, where
   `native_toolchain_rust` validates and invokes the toolchain.
2. Distinguish iOS device and simulator target triples in the build hook.

These changes allow the build hook to fall back to a reproducible Cargo build
when a matching prebuilt native library is unavailable. In particular, an
Apple Silicon simulator uses `aarch64-apple-ios-sim` instead of the incompatible
device target `aarch64-apple-ios`.

## Updating

Import a reviewed upstream tag as a clean snapshot, reapply the local patches,
then run the package tests plus noscall Android, iOS device, and iOS simulator
builds. Do not edit a copy in the global pub cache.
