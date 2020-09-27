defmodule Joken.Mixfile do
  use Mix.Project

  @version "2.3.0"

  def project do
    [
      app: :joken,
      version: @version,
      name: "Joken",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      description: description(),
      package: package(),
      deps: deps(),
      source_ref: "v#{@version}",
      source_url: "https://github.com/joken-elixir/joken",
      docs: docs_config(),
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:jason]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jose, "~> 1.10"},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: :dev},

      # Docs
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},

      # Dialyzer
      {:dialyxir, "~> 1.0.0-rc7", only: :dev, runtime: false},

      # Credo
      {:credo, "~> 1.2", only: :test, runtime: false},

      # Test
      {:junit_formatter, "~> 3.0", only: :test},
      {:stream_data, "~> 0.4", only: :test},
      {:excoveralls, "~> 0.11", only: :test}
    ]
  end

  defp description do
    """
    JWT (JSON Web Token) library for Elixir
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.txt", "CHANGELOG.md"],
      maintainers: ["Bryan Joseph", "Victor Nascimento"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/joken-elixir/joken",
        "Docs" => "http://hexdocs.pm/joken"
      }
    ]
  end

  defp docs_config do
    [
      extra_section: "GUIDES",
      extras: [
        "guides/introduction.md",
        "guides/configuration.md",
        "guides/signer.md",
        "guides/assymetric_cryptography_signers.md",
        "guides/testing.md",
        "guides/common_use_cases.md",
        "guides/migration_from_1.md",
        "guides/custom_header_arguments.md",
        {:"CHANGELOG.md", [title: "Changelog"]}
      ],
      main: "introduction"
    ]
  end
end
