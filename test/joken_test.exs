defmodule Joken.Test do
  use ExUnit.Case, async: true
  alias Joken.Signer
  import Joken

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end

  @payload %{ name: "John Doe" }

  test "signing token with binary jwk" do
    signed_token = @payload
    |> token
    |> sign(%Signer{ 
      jws: %{ "alg" => "HS256" }, 
      jwk: "secret" 
    })

    assert(signed_token.token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds")
  end

  test "signing token with jwk map" do
    signed_token = @payload
    |> token
    |> sign(%Signer{ 
      jws: %{ "alg" => "HS256" }, 
      jwk: %{ "kty" => "oct", "k" => :base64url.encode(:erlang.iolist_to_binary("secret")) }
    })

    assert(signed_token.token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds")
  end

  test "generates default token" do

    token = token()

    assert Map.has_key? token.claims, :exp
    assert Map.has_key? token.claims, :nbf
    assert Map.has_key? token.claims, :iat

    assert Map.has_key? token.validations, :exp
    assert Map.has_key? token.validations, :nbf
    assert Map.has_key? token.validations, :iat
  end

  test "can add custom claim and validation" do

    token = token()
    |> with_claim(:custom, "custom")
    |> with_validation(:custom, &(&1 == "custom"))

    assert Map.has_key? token.claims, :custom
    assert Map.has_key? token.validations, :custom
  end

  test "signs/verifies token/claims with HS256 convenience" do

    compact = @payload
    |> token
    |> sign(hs256("secret"))
    |> get_compact

    assert compact ==  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.xuEv8qrfXu424LZk8bVgr9MQJUIrp1rHcPyZw_KSsds" 

    claims = compact
    |> token
    |> verify(hs256("secret"))
    |> get_claims

    assert claims == @payload
  end

  test "signs token with HS384 convenience" do

    compact = @payload
    |> token
    |> sign(hs384("test"))
    |> get_compact

    assert compact == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k"

    claims = compact
    |> token
    |> verify(hs384("test"))
    |> get_claims

    assert claims == @payload
  end

  test "signs token with HS512 convenience" do

    compact = @payload
    |> token
    |> sign(hs512("test"))
    |> get_compact

    assert compact == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg"

    claims = compact
    |> token
    |> verify(hs512("test"))
    |> get_claims

    assert claims == @payload
  end

end
