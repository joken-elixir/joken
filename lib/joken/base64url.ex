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