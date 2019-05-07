defmodule ExAwsS3Crypto.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo "https://github.com/bmuller/ex-aws-s3-crypto"

  def project do
    [
      app: :ex_aws_s3_crypto,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Client-side encryption for AWS S3",
      package: package(),
      source_url: @repo,
      docs: [
        source_ref: "v#{@version}",
        main: "ExAws.S3.Crypto",
        formatters: ["html", "epub"]
      ]
    ]
  end

  defp aliases do
    [
      test: [
        "format --check-formatted",
        "test",
        "credo"
      ]
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Brian Muller"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      # this override is necessary until the next release of ex_aws_kms.
      # see https://github.com/ex-aws/ex_aws_kms/issues/3
      {:ex_aws, "~> 2.0", override: true},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_kms, "~> 2.0"},
      {:hackney, "~> 1.9", only: [:dev, :test]},
      {:poison, "~> 3.0"},
      {:configparser_ex, "~> 4.0", only: [:dev, :test]}
    ]
  end
end
