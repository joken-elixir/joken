defmodule Joken2.Signer do
  alias Joken2.Signer
  alias JOSE.JWS
  alias JOSE.JWT
  alias JOSE.JWK

  @hs_algorithms ["HS256", "HS384", "HS512"]
  @rs_algorithms ["RS256", "RS384", "RS512"]
  @es_algorithms ["ES256", "ES384", "ES512"]
  @ps_algorithms ["PS256", "PS384", "PS512"]
  @eddsa_algorithms ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph"]

  @map_key_algorithms @rs_algorithms ++ @es_algorithms ++ @ps_algorithms ++ @eddsa_algorithms

  # @async_crypto_key @rs

  @type jwk :: %{} | %JWK{}
  @type jws :: %{}

  @type t :: %__MODULE__{
          jwk: jwk,
          jws: jws
        }

  defstruct [:jwk, :jws]

  def algorithms do
    @hs_algorithms ++ @map_key_algorithms
  end

  def create(alg, secret) when is_binary(secret) and alg in @hs_algorithms do
    %Signer{
      jws: %{"alg" => alg},
      jwk: %{"kty" => "oct", "k" => Base.url_encode64(secret, padding: false)}
    }
  end

  def create(alg, key) when is_map(key) and alg in @map_key_algorithms do
    %Signer{jws: %{"alg" => alg}, jwk: key}
  end

  def sign(claims, %Signer{jwk: jwk, jws: jws}) when is_map(claims) do
    {_, compacted_token} = JWT.sign(jwk, jws, claims) |> JWS.compact()
    compacted_token
  end

  def parse_config(key \\ :default_key) do
    case Application.get_env(:joken, key) do
      key_config when is_binary(key_config) ->
        create("HS256", key_config)

      key_config when is_list(key_config) ->
        parse_list_config(key_config)

      _ ->
        nil
    end
  end

  defp parse_list_config(config) do
    key_alg = Keyword.get(config, :key_alg, "HS256")
    key_pem = Keyword.get(config, :key_pem)
    key_map = Keyword.get(config, :key_map)
    key_secret = Keyword.get(config, :key_secret)

    cond do
      key_alg in @hs_algorithms ->
        parse_signer_with_secret(key_alg, key_secret)

      key_alg in @map_key_algorithms ->
        parse_signer_with_pem_or_map(key_alg, key_pem, key_map)

      true ->
        raise(Joken.Error, :unrecognized_algorithm)
    end
  end

  defp parse_signer_with_secret(key_alg, nil),
    do: raise(Joken.Error, [:hs_no_secret, [key_alg: key_alg]])

  defp parse_signer_with_secret(key_alg, secret) when is_binary(secret),
    do: %Signer{
      jwk: %{"kty" => "oct", "k" => Base.url_encode64(secret, padding: false)},
      jws: %{"alg" => key_alg}
    }

  defp parse_signer_with_pem_or_map(key_alg, nil, nil),
    do: raise(Joken.Error, [:no_map_or_pem, [key_alg: key_alg]])

  defp parse_signer_with_pem_or_map(key_alg, key_pem, key_map)
       when not is_nil(key_pem) and not is_nil(key_map),
       do: raise(Joken.Error, [:provided_pem_and_map, [key_alg: key_alg]])

  defp parse_signer_with_pem_or_map(key_alg, key_pem, nil),
    do: %Signer{jwk: JOSE.JWK.from_pem(key_pem), jws: %{"alg" => key_alg}}

  defp parse_signer_with_pem_or_map(key_alg, nil, key_map) when is_map(key_map),
    do: %Signer{jwk: key_map, jws: %{"alg" => key_alg}}
end