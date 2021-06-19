defmodule ExAws.S3.Crypto do
  @moduledoc """
  `ExAws.S3.Crypto` provides [client-side encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html) support for
  [Amazon S3](https://aws.amazon.com/s3/).  It allows you to encrypt data before sending it to S3.  This particular implementation
  currently supports a [AWS KMS-managed customer master key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys)
  and assumes you have one already generated.

  This library makes heavy use of the existing [ex_aws_s3](https://hex.pm/packages/ex_aws_s3) library
  and Erlang's [crypto module](http://erlang.org/doc/man/crypto.html).  It has confirmed compatability with the [Golang AWS SDK client-encryption
  library](https://github.com/aws/aws-sdk-go/tree/master/service/s3) and uses [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
  [GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode) with 256-bit keys by default.

  ## Examples
  First, make sure you have the id for your master key (should be of the form of a UUID, like `123e4567-e89b-12d3-a456-426655440000`) and the
  bucket you're using already set up.  You should be able to make requests using `ExAws` (see
  [the ExAws docs](https://hexdocs.pm/ex_aws/ExAws.html#module-aws-key-configuration) for configuration instructions).

  To encrypt and upload an object, it's easy as pie.

      bucket = "my-awesome-bucket"
      key_id = "123e4567-e89b-12d3-a456-426655440000"
      contents = "this is some special text that should be secret"

      # Encrypt, then upload object
      request = ExAws.S3.put_object(bucket, "secret.txt.enc", contents)
      {:ok, encrypted_request} = ExAws.S3.Crypto.encrypt(request, key_id)
      ExAws.request(encrypted_request)

      # Or, use this shorter version of above
      ExAws.S3.Crypto.put_encrypted_object(bucket, "secret.txt.enc", contents, key_id)

  Decrypting is easy too, and doesn't even require knowing the original key id.

      # get encrypted object, then decrypt
      {:ok, encrypted} = ExAws.S3.get_object(bucket, "secret.txt.enc") |> ExAws.request
      {:ok, decrypted} = ExAws.S3.Crypto.decrypt(encrypted)
      IO.puts decrypted.body

      # Or, use this shorter version of above
      {:ok, decrypted} = ExAws.S3.Crypto.get_encrypted_object(bucket, "secret.txt.enc")
      IO.puts decrypted.body
  """

  alias ExAws.S3.Crypto.{AESGCMCipher, KMSWrapper}
  import ExAws.S3.Utils, only: [put_object_headers: 1]

  @doc """
  Encrypt and then create an object within a bucket.  This merely wraps creating a `ExAws.Operation.S3` request, calling `encrypt/3`, and uploading to S3
  via a call to `ExAws.request/1`.

  For example:

      bucket = "my-awesome-bucket"
      key_id = "123e4567-e89b-12d3-a456-426655440000"
      contents = "this is some special text that should be secret"

      ExAws.S3.Crypto.put_encrypted_object(bucket, "secret.txt.enc", contents, key_id)
  """
  @spec put_encrypted_object(
          bucket :: binary,
          object :: binary,
          body :: binary,
          key_id :: binary,
          opts :: ExAws.S3.put_object_opts()
        ) :: ExAws.Request.response_t()
  def put_encrypted_object(bucket, object, body, key_id, opts \\ []) do
    bucket
    |> ExAws.S3.put_object(object, body, opts)
    |> encrypt(key_id, opts)
    |> case do
      {:ok, request} ->
        ExAws.request(request)

      err ->
        err
    end
  end

  @doc """
  Get an object from a bucket and then decrypt the body.  This merely wraps sending a `ExAws.S3.get_object/3` request and then calling `decrypt/1` with
  the results.

  For example:

      {:ok, decrypted} = ExAws.S3.Crypto.get_encrypted_object("my-awesome-bucket", "secret.txt.enc")
      IO.puts decrypted.body
  """
  @spec get_encrypted_object(
          bucket :: binary,
          object :: binary,
          opts :: ExAws.S3.get_object_opts()
        ) :: ExAws.Request.response_t()
  def get_encrypted_object(bucket, object, opts \\ []) do
    bucket
    |> ExAws.S3.get_object(object, opts)
    |> ExAws.request()
    |> case do
      {:ok, response} ->
        decrypt(response)

      err ->
        err
    end
  end

  @type supported_cipher :: :aes_gcm
  @type encrypt_opts :: [{:cipher, supported_cipher}]

  @doc """
  Modify a `ExAws.Operation.S3` put operation by encrypting the body with a key generated
  from KMS using the given master key_id.

  For example:

      bucket = "my-awesome-bucket"
      key_id = "123e4567-e89b-12d3-a456-426655440000"
      contents = "this is some special text that should be secret"

      # Encrypt, then upload object
      request = ExAws.S3.put_object(bucket, "secret.txt.enc", contents)
      {:ok, encrypted_request} = ExAws.S3.Crypto.encrypt(request, key_id)
      ExAws.request(encrypted_request)
  """
  @spec encrypt(operation :: ExAws.Operation.S3.t(), key_id :: binary, opts :: encrypt_opts) ::
          ExAws.Operation.S3.t()
  def encrypt(%ExAws.Operation.S3{http_method: :put} = operation, key_id, opts \\ []) do
    cipher = Keyword.get(opts, :cipher, :aes_gcm)

    case KMSWrapper.generate_data_key(key_id) do
      {:ok, {encrypted_keyblob, key}} ->
        update_request(operation, encrypted_keyblob, key, key_id, cipher)

      err ->
        err
    end
  end

  @doc """
  Take the result of a `ExAws.S3.get_object/3` and replace the body with the decrypted value.

  For example:

      bucket = "my-awesome-bucket"
      key_id = "123e4567-e89b-12d3-a456-426655440000"

      # get encrypted object, then decrypt
      {:ok, encrypted} = ExAws.S3.get_object(bucket, "secret.txt.enc") |> ExAws.request
      {:ok, decrypted} = ExAws.S3.Crypto.decrypt(encrypted)
      IO.puts decrypted.body
  """
  @spec decrypt(response :: ExAws.Request.response_t()) :: ExAws.Request.response_t()
  def decrypt(%{body: body, headers: headers} = response) do
    case decrypt_body(body, Map.new(headers)) do
      {:ok, decrypted} ->
        {:ok, %{response | body: decrypted}}

      err ->
        err
    end
  end

  defp decrypt_body(
         body,
         %{
           "x-amz-meta-x-amz-cek-alg" => "AES/GCM/NoPadding",
           "x-amz-meta-x-amz-iv" => encoded_iv,
           "x-amz-meta-x-amz-key-v2" => encrypted_keyblob,
           "x-amz-meta-x-amz-matdesc" => matdesc
         } = headers
       ) do
    with {:ok, context} <- Jason.decode(matdesc),
         {:ok, key} <- KMSWrapper.decrypt_key(encrypted_keyblob, context),
         {:ok, decrypted} <- AESGCMCipher.decrypt(key, body, :base64.decode(encoded_iv)),
         {:ok} <- validate_length(decrypted, headers) do
      {:ok, decrypted}
    else
      err ->
        err
    end
  end

  defp decrypt_body(_, _), do: {:error, "Object missing client-side encryption metadata necssary"}

  defp validate_length(decrypted, %{"x-amz-meta-x-amz-unencrypted-content-length" => length}) do
    expected = String.to_integer(length)
    bytes = byte_size(decrypted)

    cond do
      byte_size(decrypted) == expected ->
        {:ok}

      String.length(decrypted) == expected ->
        # due to a bug in the way size was previously calculated (using String.length) don't
        # error if the String length of the decrypted result matches the expected value
        {:ok}

      true ->
        {:error, "Decrypted body size (#{bytes}) is not size expected in headers (#{expected})"}
    end
  end

  defp validate_length(_decrypted, _headers), do: {:ok}

  defp update_request(
         %ExAws.Operation.S3{headers: headers, body: contents} = operation,
         encrypted_keyblob,
         key,
         key_id,
         :aes_gcm
       )
       when is_binary(contents) do
    {:ok, {encrypted, iv}} = AESGCMCipher.encrypt(key, contents)

    # these are based on the values in the reference implementaiton here:
    # https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/s3/package-summary.html
    meta = [
      {"x-amz-key-v2", encrypted_keyblob},
      {"x-amz-iv", :base64.encode(iv)},
      {"x-amz-unencrypted-content-length", byte_size(contents)},
      {"x-amz-cek-alg", "AES/GCM/NoPadding"},
      {"x-amz-wrap-alg", "kms"},
      {"x-amz-matdesc", Jason.encode!(%{kms_cmk_id: key_id})},
      {"x-amz-tag-len", "128"}
    ]

    newheaders =
      headers
      |> Map.merge(put_object_headers(meta: meta))
      |> Map.put("content-type", "binary/octet-stream")

    {:ok, %ExAws.Operation.S3{operation | headers: newheaders, body: encrypted}}
  end

  defp update_request(_request, _encrypted_keyblob, _key, _key_id, cipher),
    do: {:error, "Cipher #{cipher} is not supported"}
end
