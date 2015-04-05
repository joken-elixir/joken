defmodule Joken.Utils do
  @moduledoc false

  def get_algorithm(_algorithm) when _algorithm == :HS384 do
    :sha384
  end

  def get_algorithm(_algorithm) when _algorithm == :HS512 do
    :sha512
  end

  def get_algorithm(_algorithm) do
    :sha256
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

  def get_current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1000000 + secs
  end

end
