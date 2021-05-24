defmodule ExAws.S3.Crypto.AESGCMCipher do
  @moduledoc """
  This module wraps the logic necessary to encrypt / decrypt using [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
  [GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode).

  See the Erlang docs for [crypto_one_time_aead](https://erlang.org/doc/man/crypto.html#crypto_one_time_aead-7) for more info.
  """

  @auth_data ""
  @tag_size 16
  # "12?  Why 12?" you ask.  Because that's what Go uses by default.
  @iv_size 12

  @doc """
  Encrypt the given contents with the supplied key.
  """
  @spec encrypt(key :: bitstring, contents :: binary) ::
          {:ok, {encrypted_result :: bitstring, initialization_vector :: bitstring}}
          | {:error, reason :: String.t()}
  def encrypt(key, contents) when is_binary(contents) do
    iv = :crypto.strong_rand_bytes(@iv_size)

    try do
      {ciphertext, ciphertag} =
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, contents, @auth_data, @tag_size, true)

      {:ok, {ciphertext <> ciphertag, iv}}
    rescue
      e in ErlangError ->
        %ErlangError{original: {_tag, _location, desc}} = e
        {:error, desc}
    end
  end

  @doc """
  Decrypt the given contents with the supplied key and initialization vector.
  """
  @spec decrypt(key :: bitstring, contents :: bitstring, iv :: bitstring) ::
          {:ok, unencrypted_result :: binary} | {:error, reason :: String.t()}
  def decrypt(key, contents, iv)
      when byte_size(contents) > @tag_size and byte_size(iv) == @iv_size do
    textsize = (byte_size(contents) - @tag_size) * 8
    <<ciphertext::bitstring-size(textsize), ciphertag::bitstring>> = contents

    :aes_256_gcm
    |> :crypto.crypto_one_time_aead(key, iv, ciphertext, @auth_data, ciphertag, false)
    |> case do
      :error ->
        {:error, "Could not decrypt contents"}

      result ->
        {:ok, result}
    end
  end

  def decrypt(_key, _contents, _iv),
    do:
      {:error,
       "Encrypted contents must be at least #{@tag_size} bytes and iv must be #{@iv_size} bytes"}
end
