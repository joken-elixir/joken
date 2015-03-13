defmodule Joken.Utils do
  alias Joken.Json, as: JSON
  @moduledoc false

  def to_map({:ok, keywords}), do: {:ok, keywords |> Enum.into(%{})}
  def to_map(error), do: error

  def get_data(jwt) do
    values = String.split(jwt, ".")
    split_count = Enum.count(values)

    if split_count < 2 or split_count > 3 do
      {:error, "Invalid JSON Web Token"}
    else
      decoded_data = Enum.map_reduce(values, 0, fn(x, acc) ->
        if acc < 2 do
            data = base64url_decode(x)
            map = JSON.decode(data)

            { map , acc + 1}  
        else
            {x, acc + 1}
        end                  
      end)
      {decoded, _} = decoded_data
      {:ok, decoded}
    end
  end

  def base64url_encode(data) do
    data
    |> :base64.encode_to_string
    |> to_string
    |> String.replace(~r/[\n\=]/, "")
    |> String.replace(~r/\+/, "-")
    |> String.replace(~r/\//, "_")
  end

  def base64url_decode(data) do
    base64_bin = String.replace(data, "-", "+") |> String.replace("_", "/")
    base64_bin = base64_bin <> case rem(byte_size(base64_bin),4) do
      2 -> "=="
      3 -> "="
      _ -> ""
    end

    :base64.decode_to_string(base64_bin) |> to_string
  end
end