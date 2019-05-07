defmodule ExAws.S3.Crypto.AESGCMCipher do
  @auth_data ""
  @tag_length 16

  def encrypt(key, contents) when is_binary(contents) do
    # "12?  Why 12?" you ask.  Because that's what the Go AWS S3 reference implemented uses.
    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, ciphertag} =
      :crypto.block_encrypt(:aes_gcm, key, iv, {@auth_data, contents, @tag_length})

    {:ok, {ciphertext <> ciphertag, iv}}
  end

  def decrypt(key, contents, iv) do
    textsize = (byte_size(contents) - @tag_length) * 8
    <<ciphertext::bitstring-size(textsize), ciphertag::bitstring>> = contents

    case :crypto.block_decrypt(:aes_gcm, key, iv, {@auth_data, ciphertext, ciphertag}) do
      :error ->
        {:error, "Could not decrypt contents"}

      result ->
        {:ok, result}
    end
  end
end
