defmodule Joken.Utils do
  @moduledoc false

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
