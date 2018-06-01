defmodule Joken.Signer.Test do
  use ExUnit.Case, async: true
  alias Joken.Signer

  doctest Signer

  # Tests below "may" break in future OTP versions. This is related to the
  # supported algorithms in the crypto module. Current expected behaviour is
  # that it will fail since OTP 20 does not support the needed algorithms.

  # Using the fallback mechanism of JOSE makes it work
  test "can parse a signer with a private OpenSSH key" do
    JOSE.crypto_fallback(true)
    on_exit(fn -> JOSE.crypto_fallback(false) end)

    assert %Signer{alg: "Ed25519"} = Signer.parse_config(:ed25519)
  end

  # No fallback, no cake
  test "fails to parse private OpenSSH key if crypto fallback is false" do
    JOSE.crypto_fallback(false)

    # We are not trying to translate this very specific error to Joken.Error
    # because it is a rarely used and would add plenty of clutter to the call
    # stack
    assert_raise ErlangError, fn ->
      Signer.parse_config(:ed25519)
    end
  end

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
end
