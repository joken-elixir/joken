defmodule Joken.Error do
  @moduledoc """
  Errors for the Joken API.
  """

  @pem_or_map """
  `PEM` is a format for encoding keys. Here is a key configuration example:

        pem_rs256: [
            signer_alg: "RS256",
            key_pem: \"\"\"
            -----BEGIN RSA PRIVATE KEY-----
            MIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==
            -----END RSA PRIVATE KEY-----  
            \"\"\"
        ]  

  This is an RSA key.

  `key_map` is a map with all the parameters needed for the key. Example:

        rs256: [
            signer_alg: "RS256",
            key_map: %{
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
        ]  

  This is also an RSA key. Please, refer to JWKs RFCs for possible parameters. Joken has a few examples in its tests that can be helpful.
  """

  defexception [:reason]

  def exception(reason), do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: :no_default_signer}),
    do: """
    Can't sign your token because couldn't create a signer. 

    To create a signer we need a key in config.exs. You can define 
    a key in your config.exs in several ways:

    1. For the default key, use `config :joken, default_signer: <key_params>`
    2. For other keys, use `config :joken, <key_name>: <key_params>`

    If you are using different than default keys, you can pass it as the second
    argument to `generate_and_sign/2` or as a parameter for `use Joken.Config`, 
    example: `use Joken.Config, default_signer: <key_name>`

    See configuration docs for possible values of <key_params>.
    """

  def message(%__MODULE__{reason: :invalid_default_claims}),
    do: """
    Invalid argument to default claims. Verify the types of the arguments to
    Joken.Config.default_claims/1.
    """

  def message(%__MODULE__{reason: :bad_validate_fun_arity}),
    do: """
    Invalid argument to validate function. 

    It must be either arity 1 or 2 where:

    1st argument - value of the claim in the passed token
    2nd argument - context passed to validate
    """

  def message(%__MODULE__{reason: :unrecognized_algorithm}),
    do: """
    Couldn't recognize the signer algorithm. 

    Possible values are: 

    #{inspect(Joken.Signer.algorithms())}
    """

  def message(%__MODULE__{reason: :claim_not_valid}),
    do: """
    Claim did not pass validation.

    Set log level to debug for more information.
    """

  def message(%__MODULE__{reason: :claim_configuration_not_valid}),
    do: """
    Claim configuration is not valid. You must have either a generation function or a 
    validation function. 

    If both are nil you don`t need a Joken.Claim configuration. You can pass any map of values
    to `Joken.Config.generate_and_sign/3`. Verify will only use claims that have a validation
    function on your configuration. Example:

        defmodule CustomClaimTest do
          use Joken.Config
        end
        
        CustomClaimTest.generate_and_sign %{"a claim without configuration" => "any value"}
    """

  def message(%__MODULE__{reason: :bad_validate_fun_arity}),
    do: """
    Claim validate function must have either arity 1 or 2.

    When arity is 1, it receives the claim value in a given JWT.

    When it is 2, besides the claim value, it receives a context map. You can pass dynamic
    values on this context and pass it to the validate function.

    See `Joken.Config.validate/3` for more information on Context
    """

  def message(%__MODULE__{reason: :wrong_key_parameters}),
    do: """
    Couldn't create a signer because there are missing parameters.

    Check the Joken.Signer.parse_config/2 documentation for the types of parameters needed
    for each type of algorithm.
    """
end
