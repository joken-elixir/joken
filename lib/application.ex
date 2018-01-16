defmodule Joken.Application do
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Chatbot.Worker, [arg1, arg2, arg3]),
    ]

    IO.puts("Initializing Joken")
    JOSE.json_module(JOSE.Jason)
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end

defmodule JOSE.Jason do
  @behaviour :jose_json

  def encode(term), do: Jason.encode!(term)

  def decode(binary) when is_binary(binary), do: Jason.decode!(binary)
end