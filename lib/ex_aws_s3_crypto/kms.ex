defmodule ExAws.S3.Crypto.KMS do
  # this module is necessary until the next release of ex_aws_kms. see https://github.com/ex-aws/ex_aws_kms/issues/3 for more details
  # Code in this module copied from https://github.com/ex-aws/ex_aws_kms/blob/master/lib/ex_aws/kms.ex
  # and released under the following license:

  # Copyright (c) 2014 CargoSense, Inc.
  # Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
  # associated documentation files (the "Software"), to deal in the Software without restriction,
  # including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  # and/or sell copies of the Software, and to permit persons to whom the Software
  # is furnished to do so, subject to the following conditions:
  # The above copyright notice and this permission notice shall be included in all copies or substantial
  # portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  # PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  # CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  # ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  @moduledoc false

  import ExAws.Utils
  alias ExAws.Operation.JSON

  @version "2014-11-01"

  def generate_data_key(key_id, opts \\ []) when is_list(opts) do
    query_params =
      opts
      |> normalize_opts
      |> Map.merge(%{
        "Action" => "GenerateDataKey",
        "Version" => @version,
        "KeyId" => key_id,
        "KeySpec" => opts[:key_spec] || "AES_256"
      })

    request(:generate_data_key, query_params)
  end

  def decrypt(ciphertext, opts \\ []) do
    query_params =
      opts
      |> normalize_opts
      |> Map.merge(%{
        "Action" => "Decrypt",
        "Version" => @version,
        "CiphertextBlob" => ciphertext
      })

    request(:decrypt, query_params)
  end

  defp request(action, params, opts \\ %{}) do
    operation =
      action
      |> Atom.to_string()
      |> Macro.camelize()

    JSON.new(
      :kms,
      %{
        data: params,
        headers: [
          {"x-amz-target", "TrentService.#{operation}"},
          {"content-type", "application/x-amz-json-1.0"}
        ]
      }
      |> Map.merge(opts)
    )
  end

  defp normalize_opts(opts) do
    opts
    |> Enum.into(%{})
    |> camelize_keys
  end
end
