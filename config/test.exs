# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :joken,
 secret_key: "test",
 parameters_module: Joken.TestPoison
