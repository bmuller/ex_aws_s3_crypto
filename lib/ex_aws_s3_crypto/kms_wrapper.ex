defmodule ExAws.S3.Crypto.KMSWrapper do
  @moduledoc """
  Utility module to wrap calls to `ExAws.KMS` to generate / decrypt [data keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys).
  """

  alias ExAws.KMS

  @doc """
  Generate a [data key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys) for the master key with the given id.
  """
  @spec generate_data_key(key_id :: String.t()) ::
          {:ok, {encrypted_blob :: String.t(), key :: bitstring}} | {:error, reason :: String.t()}
  def generate_data_key(key_id) do
    key_id
    |> KMS.generate_data_key(
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

  @doc """
  Decrypt an encrypted [data key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys).

  The context is an [encryption context](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context)
  that should generally just be a map of `%{"kms_cmk_id" => key_id}` for the master key_id used in the initial generation.
  """
  @spec decrypt_key(encrypted_key :: bitstring, context :: map) ::
          {:ok, key :: bitstring} | {:error, reason :: String.t()}
  def decrypt_key(encrypted_key, context) do
    encrypted_key
    |> KMS.decrypt(encryption_context: context)
    |> ExAws.request()
    |> case do
      {:ok, %{"Plaintext" => encoded_key}} ->
        {:ok, :base64.decode(encoded_key)}

      err ->
        err
    end
  end
end
