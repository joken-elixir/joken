defmodule Joken.Test do
  use ExUnit.Case, async: true
  alias Joken.Signer
  import Joken
  import Joken.Fixtures

  defmodule TestStruct do
    defstruct [:a, :b, :c]
  end

  defimpl Joken.Claims, for: TestStruct do
    def to_claims(%TestStruct{} = test_struct) do
      Map.from_struct(test_struct)
    end
  end

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end

  @payload %{ "name" => "John Doe" }

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

    token_struct = token()

    assert Map.has_key?(token_struct.claims_generation, "exp")
    assert Map.has_key?(token_struct.claims_generation, "nbf")
    assert Map.has_key?(token_struct.claims_generation, "iat")

    assert Map.has_key?(token_struct.validations, "exp")
    assert Map.has_key?(token_struct.validations, "nbf")
    assert Map.has_key?(token_struct.validations, "iat")
  end

  test "default validations pass" do
    signer = hs256("secret")

    assert {:ok, _} =
      token()
      |> sign(signer)
      |> verify!(signer)
  end

  test "ensure iat validation passes for same second" do

      now = current_time()

      assert {:ok, _} = @payload
      |> token
      |> with_iat(now)
      |> with_validation("iat", &(&1 <= now))
      |> sign(hs256("secret"))
      |> verify!
  end

  test "can add custom claim and validation" do

    token = token()
    |> with_claim("custom", "custom")
    |> with_validation("custom", &(&1 == "custom"))

    assert Map.has_key? token.claims, "custom"
    assert Map.has_key? token.validations, "custom"
  end

  test "generated claims become static after signing" do
    token = token()
    |> with_claim("static", "static")
    |> with_claim_generator("dynamic", fn -> "dynamic" end)

    assert Map.has_key? token.claims, "static"
    assert Map.has_key? token.claims_generation, "dynamic"

    signed = sign(token, hs256("secret"))

    assert Map.has_key? signed.claims, "static"
    assert Map.has_key? signed.claims, "dynamic"

    assert signed.claims_generation == %{}
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

  test "can skip claims" do

    compact = @payload
    |> token
    |> sign(hs512("test"))
    |> get_compact

    assert compact == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg"

    claims = compact
    |> token
    |> with_validation("name", &(&1 == "Must fail if validation is not skipped"))
    |> verify(hs512("test"), [skip_claims: ["name"]])
    |> get_claims

    assert claims == @payload
  end

  test "peek" do

    compact = @payload
    |> token
    |> sign(hs384("test"))
    |> get_compact

    claims = compact
    |> token
    |> peek

    assert claims == @payload
  end

  test "using a struct for claims" do
    token = %Joken.Token{}
    |> with_claims(%TestStruct{a: 1, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))

    assert token.claims == %{a: 1, b: 2, c: 3}

    compact = token
    |> sign(hs512("test"))
    |> get_compact

    test_struct = compact
    |> token
    |> verify(hs512("test"), as: TestStruct)
    |> get_claims

    assert test_struct == %TestStruct{a: 1, b: 2, c: 3}
  end

  test "can retrieve error" do

    error = token
    |> sign(hs256("test"))
    |> verify(hs256("TEST"))
    |> get_error

    assert error == "Invalid signature"
  end

  test "signs/verifies token with EdDSA" do

    verify_for_dynamic_token(ed25519_token, ed25519(ed25519_key))
    verify_for_dynamic_token(ed25519ph_token, ed25519ph(ed25519ph_key))
    verify_for_dynamic_token(ed448_token, ed448(ed448_key))
    verify_for_dynamic_token(ed448ph_token, ed448ph(ed448ph_key))

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

  test "can use generators of time" do

    token = %{}
    |> token
    |> with_claim_generator("exp", fn -> current_time + 60 * 1000 end)

    claims1 = token
    |> sign(hs256("secret"))
    |> verify(hs256("secret"))
    |> get_claims()

    :timer.sleep 1000

    claims2 = token
    |> sign(hs256("secret"))
    |> verify(hs256("secret"))
    |> get_claims()

    assert claims1["exp"] < claims2["exp"]

  end

  test "can use generator for custom claim" do

    token = %{}
    |> token
    |> with_claim_generator("my_claim", fn -> "Random: #{inspect :random.uniform}" end)

    claims1 = token
    |> sign(hs256("secret"))
    |> verify(hs256("secret"))
    |> get_claims()

    claims2 = token
    |> sign(hs256("secret"))
    |> verify(hs256("secret"))
    |> get_claims()

    assert claims1["my_claim"] != claims2["my_claim"]
  end

  test "can remove validations" do

    token = %Joken.Token{}
    |> with_json_module(Poison)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    assert token.error == "Invalid payload"

    token = token
    |> without_validation("a")
    |> verify(hs256("test"))

    assert token.error == nil
  end

  test "fails with invalid payload when a validated field is not present in the payload" do

    token = %Joken.Token{}
    |> with_json_module(Poison)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("d", &(&1 == 1))
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    assert token.error == "Invalid payload"
  end

  test "can fail validation wth a custom errors" do

    msg = "a should be 0"

    token = %Joken.Token{}
    |> with_json_module(Poison)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("a", &(&1 == 0), msg)
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    assert token.error == msg
    assert token.errors == [msg]
  end

  test "can fail validation wth multple custom errors" do

    a_msg = "a should be 0"
    b_msg = "b should be 0"
    c_msg = "c should be 0"

    token = %Joken.Token{}
    |> with_json_module(Poison)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("a", &(&1 == 0), a_msg)
    |> with_validation("b", &(&1 == 0), b_msg)
    |> with_validation("c", &(&1 == 0), c_msg)
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    errors = [a_msg, b_msg, c_msg]

    assert Enum.sort(token.errors) == Enum.sort(errors)
    #token.error can be any one of the errors thrown (since order is not preserved)
    assert Enum.any?(token.errors, &(&1 == token.error)) == true
  end

  test "can fail validation wth both default and custom errors" do

    a_msg = "a should be 0"
    b_msg = "b should be 2"

    token = %Joken.Token{}
    |> with_json_module(Poison)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("a", &(&1 == 0), a_msg)
    |> with_validation("b", &(&1 == 2), b_msg)
    |> with_validation("c", &(&1 == 0))
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    errors = [a_msg, "Invalid payload"]

    assert Enum.sort(token.errors) == Enum.sort(errors)
    #token.error can be any one of the errors thrown (since order is not preserved)
    assert Enum.any?(token.errors, &(&1 == token.error)) == true
  end

  test "test with JSX" do

    token = %Joken.Token{}
    |> with_json_module(:jsx)
    |> with_claims(%TestStruct{a: 2, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))
    |> sign(hs256("test"))
    |> verify(hs256("test"))

    assert token.error == "Invalid payload"

    token = token
    |> without_validation("a")
    |> verify(hs256("test"))

    assert token.error == nil
  end

  test "with_header_arg" do

    compact = @payload
    |> token
    |> with_header_arg("key", "value")
    |> sign(hs256("secret"))
    |> get_compact

    token = compact
    |> token
    |> verify(hs256("secret"))

    assert token.header == %{"key" => "value"}
  end

  test "none algorithm throws error when disabled" do
    assert_raise Joken.AlgorithmError, fn ->
      @payload
      |> token
      |> with_header_arg("key", "value")
      |> sign(none("secret"))
      |> get_compact
    end
  end

  test "none algorithm works when enabled" do
      JOSE.unsecured_signing(true)
      Application.put_env(:joken, :allow_none_algorithm, true)

      compact = @payload
      |> token
      |> with_header_arg("key", "value")
      |> sign(none("secret"))
      |> get_compact

      token = compact
      |> token
      |> verify(none("secret"))

      assert token.header == %{"key" => "value"}

      Application.put_env(:joken, :allow_none_algorithm, false)
      JOSE.unsecured_signing(false)
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
