defmodule Joken.Mixfile do
  use Mix.Project

  def project do
    [app: :joken,
     version: "0.8.0",
     elixir: "~> 1.0.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:jsx, :logger, :crypto, :timex]]
  end

  defp deps do
    [
      {:jsx, "~> 2.1.1"},
      {:timex, "~> 0.13.1"}
    ]
  end


  defp description do
    """
    JWT Library for Elixir
    """
  end

  defp package do
    [
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     contributors: ["Bryan Joseph"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/bryanjos/joken",
              "Docs" => "https://github.com/bryanjos/joken"}
    ]
  end
end
