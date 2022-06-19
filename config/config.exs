import Config

case Mix.env() do
  # Use the same key config as tests for benchmarking
  :bench ->
    import_config("test.exs")

    # Override mock adapter
    config :joken, current_time_adapter: Joken.CurrentTime.OS

  :docs ->
    :ok

  _ ->
    import_config("#{Mix.env()}.exs")
end
