defmodule ExAws.S3.Crypto do
  @moduledoc """
  Documentation for ExAwsS3Crypto.
  """

  alias ExAws.S3.Crypto.{AESGCMCipher, KMSWrapper}
  import ExAws.S3.Utils, only: [put_object_headers: 1]

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

  def encrypt(%ExAws.Operation.S3{http_method: :put} = operation, key_id, opts \\ []) do
    cipher = Keyword.get(opts, :cipher, :aes_gcm)

    case KMSWrapper.generate_data_key(key_id) do
      {:ok, {encrypted_keyblob, key}} ->
        update_request(operation, encrypted_keyblob, key, key_id, cipher)

      err ->
        err
    end
  end

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
    with {:ok, context} <- Poison.decode(matdesc),
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
    if String.length(decrypted) == String.to_integer(length) do
      {:ok}
    else
      {:error, "Unencrypted body doesn't match size expected in headers"}
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
      {"x-amz-unencrypted-content-length", String.length(contents)},
      {"x-amz-cek-alg", "AES/GCM/NoPadding"},
      {"x-amz-wrap-alg", "kms"},
      {"x-amz-matdesc", Poison.encode!(%{kms_cmk_id: key_id})},
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
