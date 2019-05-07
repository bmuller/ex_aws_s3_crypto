defmodule ExAws.S3.Crypto.KMSWrapper do
  def generate_data_key(key_id) do
    key_id
    |> ExAws.KMS.generate_data_key(
      key_spec: "AES_256",
      encryption_context: %{"kms_cmk_id" => key_id}
    )
    |> ExAws.request()
    |> case do
      {:ok, %{"CiphertextBlob" => blob, "Plaintext" => key}} ->
        {:ok, {blob, :base64.decode(key)}}

      err ->
        err
    end
  end

  def decrypt_key(encrypted_key, context) do
    encrypted_key
    |> ExAws.KMS.decrypt(encryption_context: context)
    |> ExAws.request()
    |> case do
      {:ok, %{"Plaintext" => encoded_key}} ->
        {:ok, :base64.decode(encoded_key)}

      err ->
        err
    end
  end
end
