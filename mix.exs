defmodule Joken.Mixfile do
  use Mix.Project

  @source_url "https://github.com/joken-elixir/joken"
  @version "2.6.1"

  def project do
    [
      app: :joken,
      version: @version,
      name: "Joken",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:jason]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
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
      {:jose, "~> 1.11.9"},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: :dev},

      # Docs
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # Dialyzer
      {:dialyxir, "~> 1.4.0", only: [:dev, :test], runtime: false},

      # Credo
      {:credo, "~> 1.7", only: :test, runtime: false},

      # Test
      {:junit_formatter, "~> 3.4", only: :test},
      {:stream_data, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.17", only: :test},
      {:castore, "~> 1.0", only: :test}
    ]
  end

  defp description do
    """
    JWT (JSON Web Token) library for Elixir.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.txt", "CHANGELOG.md"],
      maintainers: ["Bryan Joseph", "Victor Nascimento"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/joken/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extra_section: "GUIDES",
      extras: [
        {:"CHANGELOG.md", [title: "Changelog"]},
        {:"README.md", [title: "Readme"]},
        "guides/introduction.md",
        "guides/configuration.md",
        "guides/signers.md",
        "guides/asymmetric_cryptography_signers.md",
        "guides/testing.md",
        "guides/common_use_cases.md",
        "guides/migration_from_1.md",
        "guides/custom_header_arguments.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
