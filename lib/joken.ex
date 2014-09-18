defmodule Joken do
  @moduledoc """
    Encodes and decodes JSON Web Tokens.

    iex(1)> Joken.encode(%{username: "johndoe"}, "secret", :HS256, %{})
    {:ok,
     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog"}
    iex(2)> Joken.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog")
    {:ok, %{username: "johndoe"}}
  """

  def encode(payload, key, :HS256, headers) do
    do_encode(payload, key, :HS256, :sha256, headers)
  end

  def encode(payload, key, :HS384, headers) do
    do_encode(payload, key, :HS384, :sha384, headers)
  end

  def encode(payload, key, :HS512, headers) do
    do_encode(payload, key, :HS512, :sha512, headers)
  end

  defp do_encode(payload, key, alg, hash_alg, headers) do
    {_, headerJSON} = Map.merge(%{ alg: to_string(alg), "typ": "JWT"}, headers) |> JSEX.encode

    {status, payloadJSON} = JSEX.encode(payload)

    case status do
      :error ->
        {:error, "Error encoding map to JSON"}
      :ok ->
        header64 = base64url_encode(headerJSON)
        payload64 = base64url_encode(payloadJSON)

        signature = :crypto.hmac(hash_alg, key, "#{header64}.#{payload64}")
        signature64 = base64url_encode(signature)
        {:ok, "#{header64}.#{payload64}.#{signature64}"}
    end
  end

  def decode(jwt) do
    {status, data} = get_data(jwt)

    case status do
      :error ->
        {status, data}
      :ok ->
        {:ok, Enum.fetch!(data, 1)}
    end

  end

  defp get_data(jwt) do
    values = String.split(jwt, ".")
    if Enum.count(values) != 3 do
      {:error, "Invalid JSON Web Token"}
    else
      decoded_data = Enum.map_reduce(values, 0, fn(x, acc) ->
        data = base64url_decode(x)
        cond do
          acc < 2 ->
            {_ , map} = JSEX.decode(data, [{:labels, :atom}])
            { map , acc + 1}  
          true ->
            {data, acc + 1}                
        end
      end)
      {decoded, _} = decoded_data
      {:ok, decoded}
    end
  end

  defp base64url_encode(data) do
    data
    |> :base64.encode_to_string
    |> to_string
    |> String.replace(~r/[\n\=]/, "")
    |> String.replace(~r/\+/, "-")
    |> String.replace(~r/\//, "_")
  end

  defp base64url_decode(data) do
    base64_bin = String.replace(data, "-", "+") |> String.replace("_", "/")
    base64_bin = base64_bin <> case rem(byte_size(base64_bin),4) do
      2 -> "=="
      3 -> "="
      _ -> ""
    end

    :base64.decode_to_string(base64_bin) |> to_string
  end

end
