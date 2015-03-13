defmodule Joken.Utils do
  alias :jsx, as: JSON
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
            map = JSON.decode(data) |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
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
    data |> Base.url_encode64 |> String.rstrip(?=)
  end

  def base64url_decode(data) do
    info = data <> case rem(byte_size(data),4) do
      2 -> "=="
      3 -> "="
      _ -> ""
    end
    Base.url_decode64!(info)
  end
end
