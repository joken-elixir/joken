# Custom header arguments

By default, a header in a token is only meant for static information. This information is used for signature verification.

Common extra claims in the header might be the key id used to sign the contents, crypto algorithms and so on.

If you need to generate extra header claims, you can do that in one of two ways: 1. use a custom signer or 2. change the application configuration.

An example of creating a custom signer with extra header claims:

``` elixir
test "can set key id on signer" do
  key_id = "kid"
  signer = Signer.create("HS256", "secret", %{"kid" => key_id})
  {:ok, token, _claims} = Joken.encode_and_sign(%{}, signer)
  assert %{"kid" => ^key_id, "alg" => "HS256"} = Joken.peek_header(token)
end
```

Another example using the application configuration:

``` elixir
# config/config.exs
config :joken, signer_with_key_id: [
    signer_alg: "HS256",
    key_octet: "secret",
    jose_extra_headers: %{"kid" => "my_key_id"}
  ],

# test/sometest.exs
test "can parse with key_id" do
  {:ok, token, _claims} = Joken.encode_and_sign(%{}, Signer.parse_config(:signer_with_key_id))
  assert %{"kid" => "my_key_id", "alg" => "HS256"} = Joken.peek_header(token)
end
```

