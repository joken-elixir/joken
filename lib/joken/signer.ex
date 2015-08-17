defmodule Joken.Signer do
  alias Joken.Token

  defstruct [:jwk, :jws]

  def sign(token = %Token{signer: signer}) when not is_nil(signer) do
    sign(token, signer)
  end
  
  def sign(token, %Joken.Signer{ jws: nil, jwk: %{ "kty" => "oct" } = jwk }) do
    jws = %{ "alg" => "HS256" }
    sign(token, %Joken.Signer{ jwk: jwk, jws: jws})
  end

  def sign(token, %Joken.Signer{ jws: nil, jwk: jwk }) when is_binary(jwk) do
    jws = %{ "alg" => "HS256" }
    sign(token, %Joken.Signer{ jwk: jwk, jws: jws})
  end

  def sign(token, %Joken.Signer{ jws: jws, jwk: secret }) when is_binary(secret) do
    jwk = %{ "kty" => "oct", "k" => :base64url.encode(:erlang.iolist_to_binary(secret)) }
    sign(token, %Joken.Signer{ jwk: jwk, jws: jws})
  end

  def sign(token, signer) do
    token = %{ token | signer: signer }
    {_, compacted_token} = JOSE.JWS.compact(JOSE.JWT.sign(signer.jwk, signer.jws, token.claims))
    %{ token | token: compacted_token }
  end

  def verify(token = %Token{signer: signer = %Joken.Signer{}}) do
    verify(token, signer)
  end

  def verify(t = %Token{token: token}, %Joken.Signer{jwk: jwk, jws: %{ "alg" => algorithm}}) do
    try do
      case JOSE.JWK.verify(token, jwk) do
        {true, payload, jws} ->
          jws = :erlang.element(2, JOSE.JWS.to_map(jws))
          algorithm_string = algorithm |> to_string
          case jws["alg"] do
            ^algorithm_string -> 
              map_payload = decode_payload(t, payload)
              validate_all_claims(t, map_payload)
            _ ->
              %{ t | error: "Invalid signature algorithm" }
          end
        _ ->
          %{ t | error: "Invalid signature" }
      end
    catch
      :error, _ ->
        %{ t | error: "Missing signature" }
    end
  end

  defp decode_payload(%Token{json_module: json}, payload) when is_binary(payload) do
    json.decode! payload
  end

  defp validate_all_claims(t = %Token{validations: validations}, map_payload)
    when is_map(map_payload) do

    try do
      claims = Enum.map validations, fn(key, value) ->

        case Map.has_key? map_payload, to_string(key) do
          false ->
            raise ArgumentError
          true ->
            case value.(map_payload[key]) do
              true ->
                {key, map_payload[key]}
              false ->
                raise ArgumentError 
            end
        end
      end
      %{ t | claims: Enum.into(claims, %{}) }
    catch
      _,_ ->
        %{ t | error: "Invalid payload" }
    end
  end
  
end
