defmodule Joken.Mixfile do
  use Mix.Project

  @version "1.5.0"

  def project do
    [
      app: :joken,
      version: @version,
      elixir: "~> 1.2.3 or ~> 1.3",
      description: description(),
      package: package(),
      deps: deps(),
      consolidate_protocols: Mix.env() != :test,
      test_coverage: [tool: ExCoveralls],
      name: "Joken",
      docs: docs_config()
    ]
  end

  def application do
    [applications: [:logger, :crypto, :jose]]
  end

  defp deps do
    [
      {:jose, "~> 1.8"},
      {:plug, "~> 1.0", optional: true},
      {:poison, "~> 1.5 or ~> 2.0 or ~> 3.0", optional: true},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.13", only: :dev},
      {:jsx, "~> 2.0", only: :test},
      {:benchfella, "~> 0.3", only: :test},
      {:excoveralls, "~> 0.5", only: :test},
      {:libdecaf, "~> 0.0", only: :test},
      {:libsodium, "~> 0.0", only: :test},
      {:keccakf1600, "~> 2.0", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    JWT Library for Elixir
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
      extras: [
        "README.md": [title: "Overview", path: "overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      main: "overview",
      source_ref: "v#{@version}",
      source_url: "https://github.com/bryanjos/joken"
    ]
  end
end
