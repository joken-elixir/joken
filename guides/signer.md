# Signers

A signer is the combination of a "key" and an algorithm. That is all we need to sign and verify tokens. In JWT's vocabulary: a JWS (JSON Web Signing) with a JWK (JSON Web Key).

For each algorithm, a specific key format is expected. HS algorithms expect an octet key (a "password" like key), RS algorithms expect an RSA key and so on.

## Configuration

A signer is configured using the following parameters:

  - **signer_alg** : "HS256", "HS384" and so on
  - **key_pem** : a binary containing a key in PEM encoding format 
  - **key_openssh** : a binary containing a private key in Open SSH encoding format
  - **key_map** : a map with the raw parameters of the key
  - **key_octet** : a binary used as the password for HS algorithms only
  - **key_index** : the index of the key on a pem or openssh key set defaults to 0
  
Let's see some examples:

``` elixir
  # RS256 with a PEM encoded key
  [
    signer_alg: "RS256",
    key_pem: """ # You can pass a PEM encoded key... See below for all options.
    -----BEGIN RSA PRIVATE KEY-----
    MIIC...xcYw==
    -----END RSA PRIVATE KEY-----
    """
  ]
  
  # HS512 with an octet key
  [
    signer_alg: "HS512",
    key_octet: "a very random string"
  ]
```

## Octet keys

HS algorithms (HS256, HS384, HS512) use a simple binary for its key. You can only use `key_octet` with HS algorithms.

There is another octet key type (OKP -> octet key pair) for use with Edwards algorithms but normally we use OpenSSH private key encoding or a map with the octets so it is not mentioned here.

## All other keys

Besides HS algorithms, we have several types of keys. Each type has its own set of parameters. For example, here is a full list of RSA parameters in an RSA private key:

``` elixir
rsa_map_key = %{
  "d" =>
    "A2gHIUmJOzRGvklIA2S8wWayCXnF8NYAhOhu7woSwjioO3HRzvd3ptegSKDpPfABJuzhy7y08ug5ZcyFbN1hJBVY8NwNzpLSUK9wmXekrbTG9MT76NAiQTxV6fYK5DXPF4Cp0qghBt-tq0kQNKx4q9QEzLb9XonmXE2a10U8EWJIs972SFGhxKzf6aq6Ri7UDK607ngQyEhVmGxr3gDJLAGQ5wOap5NYIL2ufI5FYqH-Sby_Qk7299b-w4B0fl6u8isR8OlpwMLVnD-oqOBPH-65tE82hxPV0QbSmyzmg9hlVVinJ82YRBkbcu-XG9XXOhUqJJ7kafQrYkQx6BiFKQ",
  "dp" =>
    "Useg361ca8Aem1TToW8AfjOLAAEqkkR48UPMSS2Le9D4YFtAb_ud5CK2IevYl0R-4afXUzIoeiNRg4bOTAWmTwKKlmAp4B5GzlbPzAPhwQRCxzs5MiW0K-Nw30blBLWlJYDAnVEr3T3rqtgzXFLMhR5AHqM4VhWQK7QaxgaW7TE",
  "dq" =>
    "yueW-DmyJULJlJckFXfkivSO_X1sjQurDwDfyFLAnrvgy2EqJ-iq0gBVySMGw2CgeSQegTmuKinF4anL0wy85BK8tgxDULVOpjls4ej8ZQnJ2RVEjdxZLjKh-2yw-v6mbn7goko98nkRCBYMdDUBHNVcaY9bA8kdBWi-K6DgW2E",
  "e" => "AQAB",
  "kty" => "RSA",
  "n" =>
    "xnAUUvtW3ftv25jCB-hePVCnhROqH2PACVGoCybdtMYTl8qVABAR0d6T-BRzVhJzz0-UvBNFUQyVvKAFxtbQUZN2JgAm08UJrDQszqz5tTzodWexODdPuoCaWaWge_MZGhz5PwWd7Jc4bPAu0QzSVFpBP3CovSjv48Z2Eq0_LHXVjjX_Az-WaUh94mXFyAxFI_oCygtT-il1-japS3cXJJh0WddT3VKEBRYHmxDJd_LYE-KXQt3aTDhq0vI9sG2ivtFj0dc3w_YBdr4hlcr42ujSP3wLTPpTjituwHQhYP4j-zqu7J3FYaIxU4lkK9Y_DP27RxffFI9YDPJdwFkNJw",
  "p" =>
    "5cMQg_4MrOnHI44xEs6Jyt_22DCvw3K-GY046Ls50vIf2KlRALHI65SPKfVFo5hUuHkBuWnQV46tHJU0dlmfg4svPMm_581r59yXeI8W6G4FlsSiVyhFO3P5Q5ubVs7MNaqhvaqqPqR14cVvHSqjwX5jGuGAVuLhnOhZGbtb7_U",
  "q" =>
    "3RlGNrCRU-yV7TTikKJVJCIpe8vgLBkHQ61iuICd8AyHa4sXICgf2YBFgW8CAJOHKIp8g_Nl94VYpqWvN1YVDB7sFUlRpJL2yXvTKxDzUwtM5pf_D1O6lGEMQBRY-buhZHmPf5qG93LnsSqm5YOZGpZ6t6gHtYM9A6JOIgwsYys",
  "qi" =>
    "kG5Stetls18_1fvQx8rxhX2Ais0Xg0gLDUjpE_9TYcb-utq79HVKOQ_2PJGz09hQ_teqnhXhgGMubqaktl6UOSJr6B4JgcAY7yU-34EuSxp8uKLix9BVsF2cpiC4ADhjLKP9c7IQ7X7zfs336_Reb8fh9G_zRdwEfmqFy7m28Lg"
}
```

This map is in the format defined by JWK spec. Although you CAN use this format for configuring RSA keys, it is most common to use other formats like PEM (Privacy Enhanced Mail) encoded.

## PEM - Privacy Enhanced Mail

Please, don't mind the name... This is just History being unfair. If you are curious, take a look at Wikipedia's article on pem [here](https://en.wikipedia.org/wiki/Privacy-enhanced_Electronic_Mail).

Joken brings a facility for setting a PEM key. Just use the config option `key_pem`. Paste your PEM contents there and that's it. Example:

``` elixir
[
signer_alg: "RS512",
key_pem: """
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==
-----END RSA PRIVATE KEY-----
"""
```

If you are creating a signer explicitly, you need to pass the pem in a map with the key pem. Example:

``` elixir
signer = Joken.Signer.create(%{"pem" => key_pem})
```

Inside a PEM you can put several things. It may hold more than just a private key. For Joken, though, it might get a bit funky if you pass a PEM with several things in it. After all, we are trying to read a key from it and we are not actually a library for being compliant with PEM standard.

## Private vs Public keys

Many people ask why should you use an algorithm with a private/public key pair. The beauty of it is that if you generate your token with a private key anybody with a public key can verify its integrity but they can't generate a token the same way. So, the design here is that if you need another party to verify tokens (say, a client of your server) you can send it the public key and it will validate tokens generated by your private key. The other way around is not true though.

This is the main benefit. And sure is a great one :)

So, if you only call verify functions, you don't need the private key. But, if you call sign functions, you will need the private key. 

One thing that might seem confusing is that with some private keys you can **SIGN** and **VERIFY**. WTH??? Yep, some private keys contain the public key too inside of them (for example with RSA keys). So, you can sign and verify all the same with the same key.

## Benchmarks

Another misterious thing about the encoding of things is that it is preferable to use the PEM format instead of passing a map of keys with all the values. Performance wise it is just faster. You can run the benchmarks your self. They are in the benchmarks folder.

Why is that so? Well, to use the key we need to parse it into the erlang expected type that is not PEM nor JWKs maps. BUT, erlang can handle PEMs natively while it can't handle JWKs.

## Dynamic signers

All functions that receive a key argument may be passed an instance of a `Joken.Signer` in its place. This is a convenience for when you need a dynamic configuration as when you are retrieving the key from an endpoint. 

Example:

``` elixir
defmodule MyCustomAuth do
  use Joken.Config
end

# Usign default signer configuration
MyCustomAuth.generate_and_sign()

# Explicit Signer instance
MyCustomAuth.generate_and_sign(%{"some" => "extra claim"}, Joken.Signer.create("HS512", "secret"))
```

