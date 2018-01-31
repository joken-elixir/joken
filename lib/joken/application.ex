defmodule Joken.Application do
  @moduledoc """
  Application behaviour for Joken. Used to bootstrap some key options.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []

    JOSE.json_module(JOSE.Jason)
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end

defmodule JOSE.Jason do
  @moduledoc """
  Implementation of the `:jose_json` behaviour for the Jason library.

  It only delegates both `encode/1` and `decode/1` functions to Jason's calls.
  """
  @behaviour :jose_json

  @impl true
  def encode(term), do: Jason.encode!(term)

  @impl true
  def decode(binary) when is_binary(binary), do: Jason.decode!(binary)
end
