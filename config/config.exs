use Mix.Config

unless Mix.env() == :docs, do: import_config("#{Mix.env()}.exs")