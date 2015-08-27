defmodule Joken.Test do
  use ExUnit.Case, async: true
  alias Joken.Signer
  import Joken
  import Joken.Fixtures

  defmodule TestStruct do
    defstruct [:a, :b, :c]
  end

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

  test "using a struct for claims" do
    token = token()
    |> with_claims(%TestStruct{a: 1, b: 2, c: 3})
    |> with_validation(:a, &(&1 == 1))

    assert token.claims == %TestStruct{a: 1, b: 2, c: 3}

    compact = token
    |> sign(hs512("test"))
    |> get_compact

    test_struct = compact
    |> token
    |> verify(hs512("test"), TestStruct)
    |> get_claims

    assert test_struct == %TestStruct{a: 1, b: 2, c: 3}
  end

  test "signs/verifies token with ES***" do

    verify_for_dynamic_token(es256_token, es256(ec_p256_key))
    verify_for_dynamic_token(es384_token, es384(ec_p384_key))
    verify_for_dynamic_token(es512_token, es512(ec_p521_key))

  end

  test "signs/verifies token with RS***" do

    verify_for_dynamic_token(rs256_token, rs256(rsa_key))
    verify_for_dynamic_token(rs384_token, rs384(rsa_key))
    verify_for_dynamic_token(rs512_token, rs512(rsa_key))

    assert_invalid_rsa_signature(rs256_token, rs256(rsa_key2))
    assert_invalid_rsa_signature(rs384_token, rs384(rsa_key2))
    assert_invalid_rsa_signature(rs512_token, rs512(rsa_key2))
    
  end

  test "signs/verifies token with PS***" do

    verify_for_dynamic_token(ps256_token, ps256(rsa_key))
    verify_for_dynamic_token(ps384_token, ps384(rsa_key))
    verify_for_dynamic_token(ps512_token, ps512(rsa_key))

    assert_invalid_rsa_signature(ps256_token, ps256(rsa_key2))
    assert_invalid_rsa_signature(ps384_token, ps384(rsa_key2))
    assert_invalid_rsa_signature(ps512_token, ps512(rsa_key2))
    
  end

  # utility functions
  defp assert_invalid_rsa_signature(compact_token, signer) do

    result = token_config()
    |> with_compact_token(compact_token)
    |> with_signer(signer) # wrong key
    |> verify!

    assert result == {:error, "Invalid signature"}
  end
  
  # this is used to verify algorithms that will always produce
  # different tokens. The strategy is to have a token we are sure
  # is valid (generated from jwt.io for example) and validate both
  # results
  defp verify_for_dynamic_token(compact_token, signer) do

    config = token_config()
    |> with_signer(signer)
    |> sign

    compact = config |> get_compact

    {:ok, decoded_claims} = config
    |> with_compact_token(compact_token)
    |> verify!

    assert decoded_claims == @payload

    {:ok, claims} = config
    |> with_compact_token(compact)
    |> verify!

    assert claims == @payload
  end
   
end
