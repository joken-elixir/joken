defmodule Joken.Token.Bench do
  use Benchfella
  import Joken.Helpers

  setup_all do
    app = :joken
    :application.ensure_all_started(app)
    JOSE.JWA.crypto_fallback(true)
    {:ok, app}
  end

  teardown_all app do
    :application.stop(app)
  end

  defmodule BaseConfig do

    def rsa_key do
      %{"d" => "A2gHIUmJOzRGvklIA2S8wWayCXnF8NYAhOhu7woSwjioO3HRzvd3ptegSKDpPfABJuzhy7y08ug5ZcyFbN1hJBVY8NwNzpLSUK9wmXekrbTG9MT76NAiQTxV6fYK5DXPF4Cp0qghBt-tq0kQNKx4q9QEzLb9XonmXE2a10U8EWJIs972SFGhxKzf6aq6Ri7UDK607ngQyEhVmGxr3gDJLAGQ5wOap5NYIL2ufI5FYqH-Sby_Qk7299b-w4B0fl6u8isR8OlpwMLVnD-oqOBPH-65tE82hxPV0QbSmyzmg9hlVVinJ82YRBkbcu-XG9XXOhUqJJ7kafQrYkQx6BiFKQ",
        "dp" => "Useg361ca8Aem1TToW8AfjOLAAEqkkR48UPMSS2Le9D4YFtAb_ud5CK2IevYl0R-4afXUzIoeiNRg4bOTAWmTwKKlmAp4B5GzlbPzAPhwQRCxzs5MiW0K-Nw30blBLWlJYDAnVEr3T3rqtgzXFLMhR5AHqM4VhWQK7QaxgaW7TE",
        "dq" => "yueW-DmyJULJlJckFXfkivSO_X1sjQurDwDfyFLAnrvgy2EqJ-iq0gBVySMGw2CgeSQegTmuKinF4anL0wy85BK8tgxDULVOpjls4ej8ZQnJ2RVEjdxZLjKh-2yw-v6mbn7goko98nkRCBYMdDUBHNVcaY9bA8kdBWi-K6DgW2E",
        "e" => "AQAB", "kty" => "RSA",
        "n" => "xnAUUvtW3ftv25jCB-hePVCnhROqH2PACVGoCybdtMYTl8qVABAR0d6T-BRzVhJzz0-UvBNFUQyVvKAFxtbQUZN2JgAm08UJrDQszqz5tTzodWexODdPuoCaWaWge_MZGhz5PwWd7Jc4bPAu0QzSVFpBP3CovSjv48Z2Eq0_LHXVjjX_Az-WaUh94mXFyAxFI_oCygtT-il1-japS3cXJJh0WddT3VKEBRYHmxDJd_LYE-KXQt3aTDhq0vI9sG2ivtFj0dc3w_YBdr4hlcr42ujSP3wLTPpTjituwHQhYP4j-zqu7J3FYaIxU4lkK9Y_DP27RxffFI9YDPJdwFkNJw",
        "p" => "5cMQg_4MrOnHI44xEs6Jyt_22DCvw3K-GY046Ls50vIf2KlRALHI65SPKfVFo5hUuHkBuWnQV46tHJU0dlmfg4svPMm_581r59yXeI8W6G4FlsSiVyhFO3P5Q5ubVs7MNaqhvaqqPqR14cVvHSqjwX5jGuGAVuLhnOhZGbtb7_U",
        "q" => "3RlGNrCRU-yV7TTikKJVJCIpe8vgLBkHQ61iuICd8AyHa4sXICgf2YBFgW8CAJOHKIp8g_Nl94VYpqWvN1YVDB7sFUlRpJL2yXvTKxDzUwtM5pf_D1O6lGEMQBRY-buhZHmPf5qG93LnsSqm5YOZGpZ6t6gHtYM9A6JOIgwsYys",
        "qi" => "kG5Stetls18_1fvQx8rxhX2Ais0Xg0gLDUjpE_9TYcb-utq79HVKOQ_2PJGz09hQ_teqnhXhgGMubqaktl6UOSJr6B4JgcAY7yU-34EuSxp8uKLix9BVsF2cpiC4ADhjLKP9c7IQ7X7zfs336_Reb8fh9G_zRdwEfmqFy7m28Lg"}
    end

    def ec_p256_key do
      %{"crv" => "P-256", "d" => "aJhYDBNS-5yrH97PAExzWNLlJGqJwFGZmv7iJvdG4p0",
        "kty" => "EC", "x" => "LksdLpZN3ijcn_TBfRK-_tgmvws0c5_V5k0bg14RLhU",
        "y" => "ukc-JOEAWhW664SY5Q29xHlAVEDlrQwYF3-vQ_cdi1s"}
    end

    def ec_p384_key do
      %{"crv" => "P-384",
        "d" => "-iM1VuECCos2kAvvSXSsEGL-_A9-DIc4l8Z297xfSMSxiHJMYdyVMNRxHBmoJ__0",
        "kty" => "EC",
        "x" => "HgI0kaSfi-MJLcO5eP3OvLwO6pHYxiP4q-qnzqk5-TwR8MO9FweSRMpxWb-1buPZ",
        "y" => "EdONZTBTmoT_c0R7_kSW6y_VaCgB_k2iNMlARR2xqFzVS5ADkyFtCEMgOS5JmZuA"}
    end

    def ec_p521_key do
      %{"crv" => "P-521",
        "d" => "ADa5GfibXsE1DcceEmsTB99lVG2cakh247L77aa1_K9OZrlYzCIhx-HVVzwJ-KDYPOIU9q2Up8D8H-EXM_6EOYzJ",
        "kty" => "EC",
        "x" => "ANrII7yaoz0vcvYKSXg404CebQYn0-GXIBvtc3hJFh-ubu8_mdIR6_B3pa3FC_CbHZnYcSxYeRaWmDjZmWqnWsgg",
        "y" => "AH0EUWVaoVROX3_OzzQIZLuKG5546exe5-0cQ-E7thMaH6-k5cqcyIedCuX1c9lOWcXgo2NLlj4JOwSetCpOspEM"}
    end

    defmacro __using__(opts) do
      quote do
        @behaviour Joken.Config

        @opts unquote(opts)
        
        def secret_key(), do: @opts[:key] || "test"
        def algorithm(), do: @opts[:algorithm]
        def encode(map), do: Poison.encode!(map)
        def decode(binary), do: Poison.decode!(binary, keys: :atoms!)
        def claim(:exp, _payload), do: get_current_time + 3000
        def claim(:nbf, _payload), do: get_current_time - 300
        def claim(:aud, _payload), do: "benchmark"
        def claim(:iss, _payload), do: "joken benchmark"
        def claim(:iat, _paylaod), do: get_current_time
        def claim(_claim, _payload), do: nil
        def validate_claim(:exp, payload, _opt) do
          validate_time_claim(payload, :exp, "exp error", &(&1 > &2))
        end
        def validate_claim(:nbf, payload, _opt) do
          validate_time_claim(payload, :nbf, "nbf error", &(&1 < &2))
        end
        def validate_claim(:iat, payload, _opt) do
          validate_time_claim(payload, :iat, "iat error", &(&1 < &2))
        end
        def validate_claim(:aud, payload, _opt) do
          validate_claim(payload, :aud, "benchmark", "audience")
        end
        def validate_claim(:iss, payload, _opt) do
          validate_claim(payload, :iss, "joken benchmark", "iss")
        end
        def validate_claim(_claim, _payload, _options), do: :ok

        defoverridable [secret_key: 0, algorithm: 0, encode: 1, decode: 1, claim: 2, validate_claim: 3]
      end
    end
  end

  ## ------------------------------
  ## HS256, HS384, HS512 benchmarks
  ## ------------------------------

  defmodule HS256TokenGeneration do
    use BaseConfig, algorithm: :HS256
  end

  defmodule HS384TokenGeneration do
    use BaseConfig, algorithm: :HS384
  end

  defmodule HS512TokenGeneration do
    use BaseConfig, algorithm: :HS512
  end
  
  bench "HS256 token generation" do
    {:ok, _token} = Joken.Token.encode HS256TokenGeneration, %{}
    :ok
  end
  
  bench "HS384 token generation" do
    {:ok, _token} = Joken.Token.encode HS384TokenGeneration, %{}
    :ok
  end
  
  bench "HS512 token generation" do
    {:ok, _token} = Joken.Token.encode HS512TokenGeneration, %{}
    :ok
  end

  ## ------------------------------
  ## RS256, RS384, RS512 benchmarks
  ## ------------------------------

  defmodule RS256TokenGeneration do
    use BaseConfig, algorithm: :RS256, key: BaseConfig.rsa_key
  end

  defmodule RS384TokenGeneration do
    use BaseConfig, algorithm: :RS384, key: BaseConfig.rsa_key
  end

  defmodule RS512TokenGeneration do
    use BaseConfig, algorithm: :RS512, key: BaseConfig.rsa_key
  end
  
  bench "RS256 token generation" do
    {:ok, _token} = Joken.Token.encode RS256TokenGeneration, %{}
    :ok
  end

  bench "RS384 token generation" do
    {:ok, _token} = Joken.Token.encode RS384TokenGeneration, %{}
    :ok
  end
  
  bench "RS512 token generation" do
    {:ok, _token} = Joken.Token.encode RS512TokenGeneration, %{}
    :ok
  end

  ## ------------------------------
  ## ES256, ES384, ES512 benchmarks
  ## ------------------------------

  defmodule ES256TokenGeneration do
    use BaseConfig, algorithm: :ES256, key: BaseConfig.ec_p256_key
  end

  defmodule ES384TokenGeneration do
    use BaseConfig, algorithm: :ES384, key: BaseConfig.ec_p384_key
  end

  defmodule ES512TokenGeneration do
    use BaseConfig, algorithm: :ES512, key: BaseConfig.ec_p521_key
  end

  bench "ES256 token generation" do
    {:ok, _token} = Joken.Token.encode ES256TokenGeneration, %{}
    :ok
  end

  bench "ES384 token generation" do
    {:ok, _token} = Joken.Token.encode ES384TokenGeneration, %{}
    :ok
  end

  bench "ES512 token generation" do
    {:ok, _token} = Joken.Token.encode ES512TokenGeneration, %{}
    :ok
  end

  ## ------------------------------
  ## PS256, PS384, PS512 benchmarks
  ## ------------------------------

  defmodule PS256TokenGeneration do
    use BaseConfig, algorithm: :PS256, key: BaseConfig.rsa_key
  end

  defmodule PS384TokenGeneration do
    use BaseConfig, algorithm: :PS384, key: BaseConfig.rsa_key
  end

  defmodule PS512TokenGeneration do
    use BaseConfig, algorithm: :PS512, key: BaseConfig.rsa_key
  end
  
  bench "PS256 token generation" do
    {:ok, _token} = Joken.Token.encode PS256TokenGeneration, %{}
    :ok
  end

  bench "PS384 token generation" do
    {:ok, _token} = Joken.Token.encode PS384TokenGeneration, %{}
    :ok
  end
  
  bench "PS512 token generation" do
    {:ok, _token} = Joken.Token.encode PS512TokenGeneration, %{}
    :ok
  end
  
end
