defmodule Joken.Mixfile do
  use Mix.Project

  @version "2.0.0-alpha1"

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
      source_url: "https://github.com/bryanjos/joken",
      docs: docs_config(),
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
      extra_applications: [:logger, :crypto],
      mod: {Joken.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jose, "~> 1.8"},
      {:jason, "~> 1.0.0", optional: true},
      {:benchee, "~> 0.13", only: :bench},

      # Docs
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},

      # Dialyzer
      {:dialyxir, "~> 1.0.0-rc2", only: :dev, runtime: false},

      # Test
      {:junit_formatter, "~> 2.2", only: :test},
      {:stream_data, "~> 0.4", only: :test},
      {:excoveralls, "~> 0.8", only: :test}
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
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/bryanjos/joken",
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
        {"CHANGELOG.md", [title: "Changelog"]}
      ],
      main: "introduction"
    ]
  end
end
