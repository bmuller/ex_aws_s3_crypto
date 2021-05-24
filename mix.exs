defmodule ExAwsS3Crypto.MixProject do
  use Mix.Project

  @version "2.0.1"
  @repo "https://github.com/bmuller/ex_aws_s3_crypto"

  def project do
    [
      app: :ex_aws_s3_crypto,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "AWS S3 client-side encryption support",
      package: package(),
      source_url: @repo,
      docs: [
        source_ref: "v#{@version}",
        main: "ExAws.S3.Crypto",
        formatters: ["html", "epub"]
      ],
      preferred_cli_env: [test: :test, "ci.test": :test]
    ]
  end

  defp aliases do
    [
      "ci.test": [
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
      {:configparser_ex, "~> 4.0", only: [:dev, :test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_kms, "~> 2.2"},
      {:ex_aws_s3, "~> 2.2"},
      {:ex_doc, "~> 0.24", only: :dev},
      {:hackney, "~> 1.17", only: [:dev, :test]},
      {:jason, "~> 1.2"}
    ]
  end
end
