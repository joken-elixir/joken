defmodule Joken.Application do
  @moduledoc """
  Application behaviour for Joken. Used to bootstrap some key options.
  """

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []

    if Code.ensure_loaded?(Jason) do
      JOSE.json_module(JOSE.Jason)
    end

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
