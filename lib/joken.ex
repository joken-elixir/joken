defmodule Joken do
  alias :jsx, as: JSON

  @supported_algs %{ HS256: :sha256 , HS384: :sha384, HS512: :sha512 }
  @moduledoc """
    Encodes and decodes JSON Web Tokens.

    iex(1)> Joken.encode(%{username: "johndoe"}, "secret")
    {:ok,
     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog"}
    iex(2)> Joken.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog", "secret")
    {:ok, %{username: "johndoe"}}

    iex(3)> Joken.encode(%{username: "johndoe"}, "secret", :HS384, %{ iss: "self"})                                                                                                                  {:ok,
     "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1"}
    iex(4)> Joken.decode("eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1", "secret", %{ iss: "not:self"})
    {:error, "Invalid issuer"}
  """

  @doc """
    Encodes the payload into a JSON Web Token using the specified key and alg.
    Adds the specified claims to the payload as well

    alg must be either :HS256, :HS384, or :HS512
    
    default alg is :HS256

    default claims is an empty map

    returns {:ok, token} if ok, else: {:error, message}
  """
  def encode(payload, key, alg \\ :HS256, claims \\ %{}) when 
    is_map(payload) and 
    is_map(claims) and 
    is_atom(alg) and 
    is_nil(key) == false and 
    byte_size(key) > 0 
  do
    cond do
      !Map.has_key?(@supported_algs, alg) ->
        {:error, "Unsupported algorithm"}
      true ->
        headerJSON = JSON.encode(%{ alg: to_string(alg), "typ": "JWT"})
        {status, payloadJSON} = try do {:ok, Map.merge(payload, claims) |> JSON.encode} rescue _ -> {:error, nil} end

        case status do
          :error ->
            {:error, "Error encoding Map to JSON"}
          :ok ->
            header64 = base64url_encode(headerJSON)
            payload64 = base64url_encode(payloadJSON)

            signature = :crypto.hmac(@supported_algs[alg], key, "#{header64}.#{payload64}")
            signature64 = base64url_encode(signature)

            {:ok, "#{header64}.#{payload64}.#{signature64}"}
        end
    end
  end

  @doc """
    Decodes the given jwt using the given key.
    Also checks against aud, iss, and sub if given in the claims map.
    claims defaults to an empty map.

    returns {:ok, payload} if ok, else: {:error, message}
  """
  def decode(jwt, key, claims \\ %{}) when
    is_nil(jwt) == false and 
    byte_size(jwt) > 0 and
    is_nil(key) == false and 
    byte_size(key) > 0 and
    is_map(claims)
  do
    jwt
    |> get_data
    |> check_signature(key)
    |> check_exp
    |> check_nbf
    |> check_aud(Map.get(claims, :aud, nil))
    |> check_iss(Map.get(claims, :iss, nil))
    |> check_sub(Map.get(claims, :sub, nil))
    |> to_map
  end

  defp to_map({:ok, keywords}), do: {:ok, keywords |> Enum.into(%{})}
  defp to_map(error), do: error

  defp get_data(jwt) do
    values = String.split(jwt, ".")
    split_count = Enum.count(values)

    if split_count != 2 and split_count != 3 do
      {:error, "Invalid JSON Web Token"}
    else
      decoded_data = Enum.map_reduce(values, 0, fn(x, acc) ->                    
        cond do
          acc < 2 ->
            data = base64url_decode(x)
            map = JSON.decode(data) |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
            { map , acc + 1}  
          true ->
            {x, acc + 1}                
        end
      end)
      {decoded, _} = decoded_data
      {:ok, decoded}
    end
  end

  defp check_signature({:ok, data}, _key) when length(data) == 2 do
    {:ok, Enum.fetch!(data, 1)}
  end

  defp check_signature({:ok, data}, key) when length(data) == 3 do
    header = Enum.fetch!(data, 0)
    payload = Enum.fetch!(data, 1)
    jwt_signature = Enum.fetch!(data, 2)

    header64 = header |> JSON.encode |> base64url_encode
    payload64 = payload |> JSON.encode |> base64url_encode

    alg = header[:alg] |> String.to_atom

    signature = :crypto.hmac(@supported_algs[alg], key, "#{header64}.#{payload64}")

    case base64url_encode(signature) == jwt_signature do
      true ->
        {:ok, payload}
      false ->
        {:error, "Invalid signature"}
    end
  end

  defp check_signature({:ok, _data}, _key) do
    {:error, "Invalid JSON Web Token"}
  end

  defp check_signature(error, _key) do
    error
  end

  defp check_exp({:ok, payload}) do
    check_time_claim({:ok, payload}, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
  end

  defp check_exp(error) do
    error
  end

  defp check_nbf({:ok, payload}) do
    check_time_claim({:ok, payload}, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
  end

  defp check_nbf(error) do
    error
  end

  defp check_time_claim({:ok, payload}, key, error_msg, validate_time_fun) do
    key_found? = Keyword.has_key?(payload, key)
    current_time = get_current_time()
    cond do
      key_found? and validate_time_fun.(payload[key], current_time) ->
        {:ok, payload}
      key_found? and !validate_time_fun.(payload[key], current_time) ->
        {:error, error_msg}
      true ->
        {:ok, payload}        
    end
  end

  def get_current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1000000 + secs
  end

  defp check_aud({:ok, payload}, aud) do
    check_claim({:ok, payload}, :aud, aud, "audience")
  end

  defp check_aud(error, _) do
    error
  end

  defp check_iss({:ok, payload}, iss) do
    check_claim({:ok, payload}, :iss, iss, "issuer")
  end

  defp check_iss(error, _) do
    error
  end

  defp check_sub({:ok, payload}, sub) do
    check_claim({:ok, payload}, :sub, sub, "subject")
  end

  defp check_sub(error, _) do
    error
  end

  defp check_claim({:ok, payload}, key_to_check, value, full_name) do
    key_found? = Keyword.has_key?(payload, key_to_check)
    cond do
      value == nil ->
        {:ok, payload}        
      key_found? and payload[key_to_check] == value ->
        {:ok, payload}
      key_found? and payload[key_to_check] != value ->
        {:error, "Invalid #{full_name}"}
      !key_found? ->
        {:error, "Missing #{full_name}"}
      true ->
        {:ok, payload}        
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
