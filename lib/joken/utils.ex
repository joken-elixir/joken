defmodule Joken.Utils do
  @moduledoc false

  def supported_algorithms() do
    %{ HS256: :sha256 , HS384: :sha384, HS512: :sha512 }
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
