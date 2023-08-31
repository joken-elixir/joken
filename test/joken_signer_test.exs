defmodule Joken.Signer.Test do
  use ExUnit.Case, async: true
  alias Joken.{Error, Signer}

  doctest Signer

  # Tests below "may" break in future OTP versions. This is related to the
  # supported algorithms in the crypto module. Current expected behaviour is
  # that it will fail since OTP 20 does not support the needed algorithms.

  # !!! Because of a bug with JOSE we can't parse OpenSSH keys properly =/ !!!
  # https://github.com/potatosalad/erlang-jose/issues/96

  # test "can parse a signer with a private OpenSSH key" do
  #   JOSE.crypto_fallback(true)
  #   on_exit(fn -> JOSE.crypto_fallback(false) end)

  #   assert %Signer{alg: "Ed25519"} = Signer.parse_config(:ed25519)
  # end

  # No fallback, no cake
  # test "fails to parse private OpenSSH key if crypto fallback is false" do
  #   JOSE.crypto_fallback(false)

  #   # We are not trying to translate this very specific error to Joken.Error
  #   # because it is a rarely used and would add plenty of clutter to the call
  #   # stack
  #   assert_raise ErlangError, fn ->
  #     Signer.parse_config(:ed25519)
  #   end
  # end

  test "can create a signer with alg and pem" do
    pem = Application.get_env(:joken, :pem_rs256)[:key_pem]
    signer = Signer.create("RS512", %{"pem" => pem})

    assert %Signer{
             alg: "RS512",
             jws: %JOSE.JWS{
               alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS512}
             },
             jwk: %JOSE.JWK{}
           } = signer
  end

  test "can create a signer with only the public key" do
    pem = Application.get_env(:joken, :public_pem)[:key_pem]
    signer = Signer.create("RS256", %{"pem" => pem})

    assert %Signer{
             alg: "RS256",
             jws: %JOSE.JWS{
               alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256}
             },
             jwk: %JOSE.JWK{}
           } = signer
  end

  test "can create a signer from an encrypted key" do
    pem = Application.get_env(:joken, :pem_encrypted_rs256)[:key_pem]
    passphrase = Application.get_env(:joken, :pem_encrypted_rs256)[:passphrase]
    signer = Signer.create("RS256", %{"pem" => pem, "passphrase" => passphrase})

    assert %Signer{
             alg: "RS256",
             jws: %JOSE.JWS{
               alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256}
             },
             jwk: %JOSE.JWK{}
           } = signer
  end

  test "can create a signer from config using an encrypted key" do
    assert %Signer{
             alg: "RS256",
             jws: %JOSE.JWS{
               alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256}
             },
             jwk: %JOSE.JWK{}
           } = Signer.parse_config(:pem_encrypted_rs256)
  end

  test "can create a signer from a map of a key" do
    map = Application.get_env(:joken, :rs256)[:key_map]
    signer = Signer.create("RS256", map)

    assert %Signer{
             alg: "RS256",
             jws: %JOSE.JWS{
               alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256}
             },
             jwk: %JOSE.JWK{}
           } = signer
  end

  test "raise with invalid parameter" do
    assert_raise Error, Error.message(%Error{reason: :algorithm_needs_key}), fn ->
      Signer.create("RS256", "Not a map")
    end
  end

  test "raise with invalid algorithm" do
    assert_raise Error, Error.message(%Error{reason: :unrecognized_algorithm}), fn ->
      Signer.create("any algorithm", %{})
    end
  end

  test "raise when key is invalid" do
    assert_raise Error, Error.message(%Error{reason: :algorithm_needs_binary_key}), fn ->
      Signer.create("HS256", %{})
    end
  end

  test "raise when parsing invalid algorithm from configuration" do
    assert_raise Error, Error.message(%Error{reason: :unrecognized_algorithm}), fn ->
      Signer.parse_config(:bad_algorithm)
    end
  end

  test "raise with missing parameters" do
    assert_raise Error, Error.message(%Error{reason: :wrong_key_parameters}), fn ->
      Signer.parse_config(:missing_config_key)
    end
  end

  test "return error with wrong signer for token" do
    valid_signer = Signer.create("HS256", "secret")
    invalid_signer = Signer.create("HS256", "otherSecret")

    {:ok, token, _claims} = Joken.encode_and_sign(%{}, valid_signer)
    assert {:error, :signature_error} == Joken.verify(token, invalid_signer)
  end

  test "return error with invalid signer" do
    assert {:error, :empty_signer} == Joken.encode_and_sign(%{}, %Signer{})
  end

  test "can set key id on signer" do
    key_id = "kid"
    signer = Signer.create("HS256", "secret", %{"kid" => key_id})

    {:ok, token, _claims} = Joken.encode_and_sign(%{}, signer)
    assert {:ok, %{"kid" => ^key_id, "alg" => "HS256"}} = Joken.peek_header(token)
  end

  test "can parse with key_id" do
    {:ok, token, _claims} = Joken.encode_and_sign(%{}, Signer.parse_config(:with_key_id))

    assert {:ok, %{"kid" => "my_key_id", "alg" => "HS256"}} = Joken.peek_header(token)
  end

  test "can override typ header claim" do
    signer = Signer.create("HS256", "secret", %{"typ" => "SOMETHING_ELSE"})
    {:ok, token, _claims} = Joken.encode_and_sign(%{}, signer)
    assert {:ok, %{"typ" => "SOMETHING_ELSE"}} = Joken.peek_header(token)
  end
end
