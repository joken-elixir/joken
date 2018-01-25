jwk_hs256 = JOSE.JWK.generate_key({:oct, 16})
jwk_hs384 = JOSE.JWK.generate_key({:oct, 24})
jwk_hs512 = JOSE.JWK.generate_key({:oct, 32})

jws_hs256 = JOSE.JWS.from_map(%{"alg" => "HS256", "typ" => "JWT"})
jws_hs384 = JOSE.JWS.from_map(%{"alg" => "HS384", "typ" => "JWT"})
jws_hs512 = JOSE.JWS.from_map(%{"alg" => "HS512", "typ" => "JWT"})

Benchee.run(%{
  "JOSE HS256" => fn ->
    # Same as default claims for Joken
    jwt = %{
      "exp" => Joken.CurrentTime.current_time() + 2 * 60 * 60,
      "iss" => "Joken",
      "nbf" => Joken.CurrentTime.current_time(),
      "iat" => Joken.CurrentTime.current_time()
    }

    JOSE.JWT.sign(jwk_hs256, jws_hs256, jwt) |> JOSE.JWS.compact()
  end,
  "JOSE HS384" => fn ->
    # Same as default claims for Joken
    jwt = %{
      "exp" => Joken.CurrentTime.current_time() + 2 * 60 * 60,
      "iss" => "Joken",
      "nbf" => Joken.CurrentTime.current_time(),
      "iat" => Joken.CurrentTime.current_time()
    }

    JOSE.JWT.sign(jwk_hs384, jws_hs384, jwt) |> JOSE.JWS.compact()
  end,
  "JOSE HS512" => fn ->
    # Same as default claims for Joken
    jwt = %{
      "exp" => Joken.CurrentTime.current_time() + 2 * 60 * 60,
      "iss" => "Joken",
      "nbf" => Joken.CurrentTime.current_time(),
      "iat" => Joken.CurrentTime.current_time()
    }

    JOSE.JWT.sign(jwk_hs512, jws_hs512, jwt) |> JOSE.JWS.compact()
  end
})