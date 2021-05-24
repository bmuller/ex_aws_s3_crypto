# ExAws.S3.Crypto
[![Build Status](https://secure.travis-ci.org/bmuller/ex_aws_s3_crypto.png?branch=master)](https://travis-ci.org/bmuller/ex_aws_s3_crypto)
[![Hex pm](http://img.shields.io/hexpm/v/ex_aws_s3_crypto.svg?style=flat)](https://hex.pm/packages/ex_aws_s3_crypto)
[![API Docs](https://img.shields.io/badge/api-docs-lightgreen.svg?style=flat)](https://hexdocs.pm/ex_aws_s3_crypto/)

`ExAws.S3.Crypto` provides [client-side encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html) support for
[Amazon S3](https://aws.amazon.com/s3/).  It allows you to encrypt data before sending it to S3.  This particular implementation
currently supports a [AWS KMS-managed customer master key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys)
and assumes you have one already generated.

`ExAws.S3.Crypto` makes heavy use of the existing [ex_aws_s3](https://hex.pm/packages/ex_aws_s3) library
and Erlang's [crypto module](http://erlang.org/doc/man/crypto.html).  It has confirmed compatability with the [Golang AWS SDK client-encryption
library](https://github.com/aws/aws-sdk-go/tree/master/service/s3) and uses [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
[GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) with 256-bit keys by default.

**Note:** As of version 2.0, OTP version 22 or greater is required due to changes in the `:crypto` library.

## Installation

To install ExAws.S3.Crypto, just add an entry to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_aws_s3_crypto, "~> 2.0"}
  ]
end
```

(Check [Hex](https://hex.pm/packages/ex_aws_s3_crypto) to make sure you're using an up-to-date version number.)

## Usage
First, make sure you have the id for your master key (should be of the form of a UUID, like `123e4567-e89b-12d3-a456-426655440000`) and the
bucket you're using already set up.  You should be able to make requests using `ExAws` (see
[the ExAws docs](https://hexdocs.pm/ex_aws/ExAws.html#module-aws-key-configuration) for configuration instructions).

To encrypt and upload an object, it's easy as pie.

```elixir
bucket = "my-awesome-bucket"
key_id = "123e4567-e89b-12d3-a456-426655440000"
contents = "this is some special text that should be secret"

# Encrypt, then upload object
request = ExAws.S3.put_object(bucket, "secret.txt.enc", contents)
{:ok, encrypted_request} = ExAws.S3.Crypto.encrypt(request, key_id)
ExAws.request(encrypted_request)

# Or, use this shorter version of above
ExAws.S3.Crypto.put_encrypted_object(bucket, "secret.txt.enc", contents, key_id)
```

Decrypting is easy too, and doesn't even require knowing the original key id.

```elixir
# get encrypted object, then decrypt
{:ok, encrypted} = ExAws.S3.get_object(bucket, "secret.txt.enc") |> ExAws.request
{:ok, decrypted} = ExAws.S3.Crypto.decrypt(encrypted)
IO.puts decrypted.body

# Or, use this shorter version of above
{:ok, decrypted} = ExAws.S3.Crypto.get_encrypted_object(bucket, "secret.txt.enc")
IO.puts decrypted.body
```

See [the docs](https://hexdocs.pm/ex_aws_s3_crypto) for more examples.

## Running Tests

To run tests:

```shell
$ mix test
```

## Reporting Issues

Please report all issues [on github](https://github.com/bmuller/ex_aws_s3_crypto/issues).
