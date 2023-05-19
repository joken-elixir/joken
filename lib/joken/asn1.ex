defmodule Joken.ASN1 do
  @moduledoc """
  Module for handling the various definitons of Erlang's :public_key record definitions.

  Inspired by the library x509 by @voltone
  """

  require Record

  # Gets all definitions (including the ones in dependant headers)
  records = Record.extract_all(from_lib: "public_key/include/public_key.hrl")

  record_keys_normalized =
    Enum.map(Keyword.keys(records), fn rec ->
      rec
      |> Atom.to_string()
      |> String.replace("-", "")
      |> Macro.underscore()
      |> String.to_atom()
    end)

  @record_mappings Enum.zip(record_keys_normalized, records)

  Enum.each(@record_mappings, fn {name, {pubkey_name, definitions}} ->
    Record.defrecord(name, pubkey_name, definitions)
  end)

  def record_mappings, do: @record_mappings
end
