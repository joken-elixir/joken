if Code.ensure_loaded?(Jason) do
  defmodule JOSE.Jason do
    @moduledoc """
    Implementation of the `:jose_json` behaviour for the Jason library.

    It only delegates both `encode/1` and `decode/1` functions to Jason's calls.

    Future work might want to encode/decode specific types like Poison's implementation.
    """
    @behaviour :jose_json

    @impl true
    def encode(term), do: Jason.encode!(term)

    @impl true
    def decode(binary) when is_binary(binary), do: Jason.decode!(binary)
  end
end
