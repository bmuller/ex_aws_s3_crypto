defmodule ExAws.S3.Crypto.AESGCMCipherTest do
  use ExUnit.Case
  alias ExAws.S3.Crypto.AESGCMCipher

  describe "When encrypting using AES GCM" do
    test "encryption should work" do
      # AES 256
      key = :crypto.strong_rand_bytes(32)
      contents = "hello there, this is secret"
      {:ok, {crypted, iv}} = AESGCMCipher.encrypt(key, contents)

      textsize = (byte_size(crypted) - 16) * 8
      <<ciphertext::bitstring-size(textsize), ciphertag::bitstring>> = crypted
      decrypted = :crypto.block_decrypt(:aes_gcm, key, iv, {"", ciphertext, ciphertag})
      assert decrypted == contents
    end

    test "bad input should return error" do
      contents = "hello there, this is secret"
      assert match?({:error, _}, AESGCMCipher.encrypt(<<>>, contents))
    end
  end

  describe "When decrypting using AES GCM" do
    test "decryption should work" do
      contents = "hello there, this is secret"
      key = :crypto.strong_rand_bytes(32)
      iv = :crypto.strong_rand_bytes(12)
      {ciphertext, ciphertag} = :crypto.block_encrypt(:aes_gcm, key, iv, {"", contents, 16})
      crypted = ciphertext <> ciphertag

      assert AESGCMCipher.decrypt(key, crypted, iv) == {:ok, contents}
    end

    test "bad input should return error" do
      key = :crypto.strong_rand_bytes(32)
      iv = :crypto.strong_rand_bytes(12)
      badcontents = :crypto.strong_rand_bytes(123)
      assert match?({:error, _}, AESGCMCipher.decrypt(key, badcontents, <<>>))
      assert match?({:error, _}, AESGCMCipher.decrypt(key, <<>>, iv))
    end
  end
end
