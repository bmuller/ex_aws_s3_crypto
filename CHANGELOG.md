# Changelog

## v3.0.0 (2021-06-19)

### Bug Fixes

  * Previous versions incorrectly stored `String.length/1` (rather than `byte_size`) in content-length metadata.

## v2.0.1 (2021-05-24)

### Bug Fixes

  * Ensure that tests pass in OTP version 22-24

## v2.0.0 (2021-05-24)

### Enhancements

  * Full support for the crypto changes added in OTP 22

### Hard-deprecations

  * No OTP versions below 22 are supported.

## v1.0.0 (2020-05-24)

### Enhancements

  * Was able to add dependency on ex_aws_kms after new release there, and removed duplicate code.

### Bug Fixes

  * Fixed typo in example `go` code, updated docs for testing compatability.
