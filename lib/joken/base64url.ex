# This file overrides a module used by JOSE for performing base64 url encode/decode
#
# After profiling, the Elixir Base implementation has higher performance and so we
# override the default JOSE implementation with one that uses Elixir.Base.

# Ignore module conflicts because that is what we are after here
Code.compiler_options(ignore_module_conflict: true)

defmodule :base64url do
  @moduledoc """
  Redefines default :base64url dependency of erlang-jose for taking advantage from the faster
  `Base` implementation from Elixir. This is ~2x the speed of base64url implementation.

  It provides only encode/1 and decode/1 but no encode_mime/1
  """
  @doc false
  def encode(term) when is_binary(term),
    do: Base.url_encode64(term, ignore: :whitespace, padding: false)

  def encode(term) when is_list(term), do: :erlang.iolist_to_binary(term) |> encode()

  @doc false
  def decode(term) when is_binary(term),
    do: Base.url_decode64!(term, ignore: :whitespace, padding: false)

  def decode(term) when is_list(term), do: :erlang.iolist_to_binary(term) |> decode()
end

# Turn back module conflicts
Code.compiler_options(ignore_module_conflict: false)
