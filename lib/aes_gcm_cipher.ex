defmodule ExAws.S3.Crypto.AESGCMCipher do
  @auth_data ""
  @tag_size 16
  # "12?  Why 12?" you ask.  Because that's what Go uses by default.
  @iv_size 12

  def encrypt(key, contents) when is_binary(contents) do
    iv = :crypto.strong_rand_bytes(@iv_size)

    try do
      {ciphertext, ciphertag} =
        :crypto.block_encrypt(:aes_gcm, key, iv, {@auth_data, contents, @tag_size})

      {:ok, {ciphertext <> ciphertag, iv}}
    rescue
      e in ArgumentError ->
        {:error, e}
    end
  end

  def decrypt(key, contents, iv)
      when byte_size(contents) > @tag_size and byte_size(iv) == @iv_size do
    textsize = (byte_size(contents) - @tag_size) * 8
    <<ciphertext::bitstring-size(textsize), ciphertag::bitstring>> = contents

    case :crypto.block_decrypt(:aes_gcm, key, iv, {@auth_data, ciphertext, ciphertag}) do
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
