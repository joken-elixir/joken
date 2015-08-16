defmodule Joken.New.Test do
  use ExUnit.Case
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

end