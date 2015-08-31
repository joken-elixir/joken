defmodule Joken.Mixfile do
  use Mix.Project

  def project do
    [app: :joken,
     version: "0.16.0-dev",
     elixir: "~> 1.0.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger, :crypto, :jose]]
  end

  defp deps do
    [
      {:jose, "~> 1.2"},
      {:plug, "~> 1.0", optional: true},
      {:poison, "~> 1.4", optional: true},
      {:earmark, "~> 0.1", only: :docs},
      {:ex_doc, "~> 0.8", only: :docs},
      {:jsx, "~> 2.0", only: :test},
      {:benchfella, "~> 0.2", only: :test}      
    ]
  end

  defp description do
    """
    JWT Library for Elixir
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*", "CHANGELOG*"],
      contributors: ["Bryan Joseph", "Victor Nascimento"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/bryanjos/joken",
               "Docs" => "http://hexdocs.pm/joken"}
    ]
  end
end
