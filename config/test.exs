# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :my_otp_app,
 secret_key: "test",
 algorithm: :HS384,
 json_module: TestPoison

config :my_other_otp_app,
 secret_key: "test",
 json_module: TestPoison
