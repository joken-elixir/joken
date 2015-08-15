defmodule Joken.Token.Test do
  use ExUnit.Case

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end

  @moduledoc """
  Tests calling the Joken.Token module directly
  """
  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  @unsorted_payload %{
    iss: "https://example.com/",
    sub: "example|123456",
    aud: "abc123",
    iat: 1428371188
  }
  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim @unsorted_payload, secret "test"
  @unsorted_payload_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tLyIsInN1YiI6ImV4YW1wbGV8MTIzNDU2IiwiYXVkIjoiYWJjMTIzIiwiaWF0IjoxNDI4MzcxMTg4fQ.w9Elb3Ogomd1hm0bAvjbrOPIDhZhgOxckG_ztDJVhJs"

  @poison_json_module Joken.TestPoison
  @jsx_json_module Joken.TestJsx

  # base config that is overriden in each test
  defmodule BaseConfig do

    @moduledoc false

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

    defmacro __using__(_opts) do
      quote do
        @behaviour Joken.Config

        def secret_key(), do: "test"
        def algorithm(), do: :HS256
        def encode(map), do: Poison.encode!(map)
        def decode(binary), do: Poison.decode!(binary, keys: :atoms!)
        def claim(_claim, _payload), do: nil
        def validate_claim(_claim, _payload, _options), do: :ok

        defoverridable [secret_key: 0, algorithm: 0, encode: 1, decode: 1, claim: 2, validate_claim: 3]
      end
    end
  end

  test "encode and decode with ES256 (Poison)" do

    defmodule DecodeES256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p256_key
      def algorithm(), do: :ES256
    end

    {:ok, token} = Joken.Token.encode(DecodeES256, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ozw2CHDqSE1t5CXXP50x52tr07Nj7HGSBWGytDj93gcHxS65TJ6Tv0RrOei-WtauDN3beXF5e7lZ8c5MPwx0-w")
    {:ok, decoded_payload} = Joken.Token.decode(DecodeES256, "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ozw2CHDqSE1t5CXXP50x52tr07Nj7HGSBWGytDj93gcHxS65TJ6Tv0RrOei-WtauDN3beXF5e7lZ8c5MPwx0-w")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodeES256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with ES384 (Poison)" do

    defmodule DecodeES384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p384_key
      def algorithm(), do: :ES384
    end

    {:ok, token} = Joken.Token.encode(DecodeES384, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.H1Y9Z3hhYff4kIWt6b1F-S1hNP74DRqYH9Jg41sJTitKC4wmYEAfKkQk6O7Z5nReL-4bhL2TZwl-rutG2tadVSUePeGlYR0AIiBCgJGf9dZPfYYF-toJ37wefKz0Cq78")
    {:ok, decoded_payload} = Joken.Token.decode(DecodeES384, "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.H1Y9Z3hhYff4kIWt6b1F-S1hNP74DRqYH9Jg41sJTitKC4wmYEAfKkQk6O7Z5nReL-4bhL2TZwl-rutG2tadVSUePeGlYR0AIiBCgJGf9dZPfYYF-toJ37wefKz0Cq78")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodeES384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with ES512 (Poison)" do

    defmodule DecodeES512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p521_key
      def algorithm(), do: :ES512
    end

    {:ok, token} = Joken.Token.encode(DecodeES512, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ASkU80v3zU8Qa0Xdz3fJTkwRn5yEoYIUpEp4R7IH8iEEq1AJqhJv7VLSrACfiC8TdooBsa2qitA7qCOF12XgpHQzAJCvs1ryhEwmgnB3a5_aNW-5_s3REmAvmaA587Au0C-vBlRFvymrYRAITUN0Vb9z0giBAu82GcEaRuTvXblYeQXz")
    {:ok, decoded_payload} = Joken.Token.decode(DecodeES512, "eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ASkU80v3zU8Qa0Xdz3fJTkwRn5yEoYIUpEp4R7IH8iEEq1AJqhJv7VLSrACfiC8TdooBsa2qitA7qCOF12XgpHQzAJCvs1ryhEwmgnB3a5_aNW-5_s3REmAvmaA587Au0C-vBlRFvymrYRAITUN0Vb9z0giBAu82GcEaRuTvXblYeQXz")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodeES512, token)
    assert(@payload == decoded_payload)
  end
  
  test "encode and decode with HS256 (Poison)" do
    {:ok, token} = Joken.Token.encode(@poison_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.Token.decode(@poison_json_module, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with HS384 (Poison)" do

    defmodule DecodeHS384 do
      use BaseConfig

      def algorithm(), do: :HS384
    end

    {:ok, token} = Joken.Token.encode(DecodeHS384, @payload)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.Token.decode(DecodeHS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with HS512 (Poison)" do

    defmodule DecodeHS512 do
      use BaseConfig

      def algorithm(), do: :HS512
    end

    {:ok, token} = Joken.Token.encode(DecodeHS512, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.Token.decode(DecodeHS512, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS256 (Poison)" do

    defmodule DecodePS256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS256
    end

    {:ok, token} = Joken.Token.encode(DecodePS256, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.s-2hYCN-GpKbaJpTByhOfdGQE2yWa8wZR9y4w9c1xh5IlCothIvSiF4MMPWGYqf7mOYRij_pftsd3s0AjDCZBTPOua8o9_yJlI_ohfly-HAvZ3vRYEL126zOQ-vQWoZI_nmDjzjCBkYTElzi6RC6R8FyE7SpVR6btFixcOjqsbs1y8to60NE5bYgiBXkT1BA2ADGY3QLxCWvmrFkyRtfWaBmB74iHQSDat0k9T0A8z43M9CG29UhyhnwEwR938OFRdMyWMqREh4IoIIjn-UYAQ0IcHK3TiqZHB05X_ZZ6VZh3szmlKMebzucN85rCYXai6eGvKFIERrwBKkxhSNDeg")
    {:ok, decoded_payload} = Joken.Token.decode(DecodePS256, "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.s-2hYCN-GpKbaJpTByhOfdGQE2yWa8wZR9y4w9c1xh5IlCothIvSiF4MMPWGYqf7mOYRij_pftsd3s0AjDCZBTPOua8o9_yJlI_ohfly-HAvZ3vRYEL126zOQ-vQWoZI_nmDjzjCBkYTElzi6RC6R8FyE7SpVR6btFixcOjqsbs1y8to60NE5bYgiBXkT1BA2ADGY3QLxCWvmrFkyRtfWaBmB74iHQSDat0k9T0A8z43M9CG29UhyhnwEwR938OFRdMyWMqREh4IoIIjn-UYAQ0IcHK3TiqZHB05X_ZZ6VZh3szmlKMebzucN85rCYXai6eGvKFIERrwBKkxhSNDeg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodePS256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS384 (Poison)" do

    defmodule DecodePS384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS384
    end

    {:ok, token} = Joken.Token.encode(DecodePS384, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.Pgc1QLw5k6-SbqkYq1MHHtm1MRJ3OUicueG-7CuufED06aRzWGbM6bdY0WxknGEUyH4VBe3_9y8hc-s77uLXhgkJIttmkXDWSLOcE7_BmbEe91848nbaAPZS0aKxJXHkAgx6CrLkVMQrKytwECtnWW-cz8mu1iOv5teZNc8UywzflssAQfaSWoBSUvGL5TEfDQWkftBiidkACA0K9Epdk0pZk1qRpAgw11YW5C3Dybrxp8M_osctfHfDHOxF5WUyS_sGiPwYRHU2R3-eFNlcE15NTf24Jp5pcuM3JP41OGm4aZiA2QhDhyAOtzWmJSNuKN0XaCiSnEuUvwbkPpRSPg")
    {:ok, decoded_payload} = Joken.Token.decode(DecodePS384, "eyJhbGciOiJQUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.Pgc1QLw5k6-SbqkYq1MHHtm1MRJ3OUicueG-7CuufED06aRzWGbM6bdY0WxknGEUyH4VBe3_9y8hc-s77uLXhgkJIttmkXDWSLOcE7_BmbEe91848nbaAPZS0aKxJXHkAgx6CrLkVMQrKytwECtnWW-cz8mu1iOv5teZNc8UywzflssAQfaSWoBSUvGL5TEfDQWkftBiidkACA0K9Epdk0pZk1qRpAgw11YW5C3Dybrxp8M_osctfHfDHOxF5WUyS_sGiPwYRHU2R3-eFNlcE15NTf24Jp5pcuM3JP41OGm4aZiA2QhDhyAOtzWmJSNuKN0XaCiSnEuUvwbkPpRSPg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodePS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS512 (Poison)" do

    defmodule DecodePS512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS512
    end

    {:ok, token} = Joken.Token.encode(DecodePS512, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.GWrtPFuCQhrlfq_iCDqXkl95AwtuRTU5KaMbIW3s1By4dvwpV5lCIG5atm53eHSTxPm4__Ms9yNdUdu9DWVZLMoP39EiXozgnd7VskWhv9CB3ATo5TNpBuGKnricZGcXMg0J8_3q6a5wZZ5U0W2rynpKQFU0iRqXZlw5xdlTU6GPSOttTfGr1lu8tt484xlS5r5oW46cdwerXmAfQuTNq8xaMFud7Ssj8iGpEE1CkR1IGRySxppcn8-QoyI1JOmNlIn-7610nyMkLfiZs8lrVZqdf_1Lp368vxYK6s-_rtF_TlIItfGmrNro6wEwxfJHm-OIhlKSIWKjVyMk-obJrg")
    {:ok, decoded_payload} = Joken.Token.decode(DecodePS512, "eyJhbGciOiJQUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.GWrtPFuCQhrlfq_iCDqXkl95AwtuRTU5KaMbIW3s1By4dvwpV5lCIG5atm53eHSTxPm4__Ms9yNdUdu9DWVZLMoP39EiXozgnd7VskWhv9CB3ATo5TNpBuGKnricZGcXMg0J8_3q6a5wZZ5U0W2rynpKQFU0iRqXZlw5xdlTU6GPSOttTfGr1lu8tt484xlS5r5oW46cdwerXmAfQuTNq8xaMFud7Ssj8iGpEE1CkR1IGRySxppcn8-QoyI1JOmNlIn-7610nyMkLfiZs8lrVZqdf_1Lp368vxYK6s-_rtF_TlIItfGmrNro6wEwxfJHm-OIhlKSIWKjVyMk-obJrg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(DecodePS512, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS256 (Poison)" do

    defmodule DecodeRS256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS256
    end

    {:ok, token} = Joken.Token.encode(DecodeRS256, @payload)
    assert(token == "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ")

    {:ok, decoded_payload} = Joken.Token.decode(DecodeRS256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS384 (Poison)" do

    defmodule DecodeRS384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS384
    end

    {:ok, token} = Joken.Token.encode(DecodeRS384, @payload)
    assert(token == "eyJhbGciOiJSUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.XpXgnjgYH-SIQMPg8xnNXXG5RV6CQhWajHoJbf44_fT70ZbpVDSeQopNXjQg3ClFDdbTbyGeR-cCfgr1xMqdWWpbmuCn13CS9-918WD0fENkrDMb_ErFyft0XiWTLeQlW_BaLP0-sqAfY8-XsiDMbClP2hgAdyV9iA-aFJ2S5HVKI_j68WmjcvwNGPNJcfhTEpx0mMroBj1qNBRNS5p94L-QRieZgtbs5ikrn7OAo5NME6DGtrDLd1deeN84r3nGTqQODiK22o-LSjnpWHKw0iXjQymFrnnd7B_IgYiWu7X4ZPmUy_wMSYT9O8k00sfE_VRVV5Uq2qlNpCYWv9LlLA")

    {:ok, decoded_payload} = Joken.Token.decode(DecodeRS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS512 (Poison)" do

    defmodule DecodeRS512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS512
    end

    {:ok, token} = Joken.Token.encode(DecodeRS512, @payload)
    assert(token == "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.aw9j2S7aqohX_dGWJYrA1btgQE46Dtiy-7S9J70-k_Tm2ElepqgAj25gBDqLWkGuhKKncHWlablS2fLpmzmh-FqPbamBms6Wb9oL73H-BN4RbaCV_GGtqRFJGGHiMcKMTkbAqFps0P9xyAlr77mjplC8yXvS-gnRw3Y1z3vpgmju9G7DSyKYNUea0-_7VkT-dq0DQTiAxpaBNz4bV4Ycuduu4J24opTAGnZKR3QMdLJnoM1NRhCtpAo8twXi5He4yIFiCoz5Cjy6uWkY8mtJchC5BEES-EnbqsTBY8ScOH3tQuR9gFxunHGrfwOvT6OgX2Y5D-ZjVC6WuFGy9tPb7w")

    {:ok, decoded_payload} = Joken.Token.decode(DecodeRS512, token)
    assert(@payload == decoded_payload)
  end

  test "decode token generated with un-sorted keys (Poison)" do
    {:ok, _} = Joken.Token.encode(@poison_json_module, @payload)
    {:ok, decoded_payload} = Joken.Token.decode(@poison_json_module, @unsorted_header_token)
    assert(@payload == decoded_payload)
  end

  test "signature validation (Poison)" do
    {:ok, token} = Joken.Token.encode(@poison_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")
    {:ok, _} = Joken.Token.decode(@poison_json_module, token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.Token.decode(@poison_json_module, new_token)
    assert(mesg == "Invalid signature") 
  end

  test "signature validation unsorted payload (Poison)" do
    assert {:ok, _} = Joken.Token.decode(@poison_json_module, @unsorted_payload_token)
  end

  test "error with invalid algorithm" do

    defmodule Decode1024 do
      use BaseConfig

      def algorithm(), do: :HS1024
    end

    {:error, message} = Joken.Token.encode(Decode1024, @payload)
    assert message == "Unsupported algorithm"
  end

  test "encode and decode with ES256 (JSX)" do

    defmodule TestJsxES256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p256_key
      def algorithm(), do: :ES256

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxES256, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ozw2CHDqSE1t5CXXP50x52tr07Nj7HGSBWGytDj93gcHxS65TJ6Tv0RrOei-WtauDN3beXF5e7lZ8c5MPwx0-w")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES256, "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ozw2CHDqSE1t5CXXP50x52tr07Nj7HGSBWGytDj93gcHxS65TJ6Tv0RrOei-WtauDN3beXF5e7lZ8c5MPwx0-w")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with ES384 (JSX)" do

    defmodule TestJsxES384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p384_key
      def algorithm(), do: :ES384

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxES384, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.H1Y9Z3hhYff4kIWt6b1F-S1hNP74DRqYH9Jg41sJTitKC4wmYEAfKkQk6O7Z5nReL-4bhL2TZwl-rutG2tadVSUePeGlYR0AIiBCgJGf9dZPfYYF-toJ37wefKz0Cq78")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES384, "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.H1Y9Z3hhYff4kIWt6b1F-S1hNP74DRqYH9Jg41sJTitKC4wmYEAfKkQk6O7Z5nReL-4bhL2TZwl-rutG2tadVSUePeGlYR0AIiBCgJGf9dZPfYYF-toJ37wefKz0Cq78")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with ES512 (JSX)" do

    defmodule TestJsxES512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.ec_p521_key
      def algorithm(), do: :ES512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxES512, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ASkU80v3zU8Qa0Xdz3fJTkwRn5yEoYIUpEp4R7IH8iEEq1AJqhJv7VLSrACfiC8TdooBsa2qitA7qCOF12XgpHQzAJCvs1ryhEwmgnB3a5_aNW-5_s3REmAvmaA587Au0C-vBlRFvymrYRAITUN0Vb9z0giBAu82GcEaRuTvXblYeQXz")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES512, "eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.ASkU80v3zU8Qa0Xdz3fJTkwRn5yEoYIUpEp4R7IH8iEEq1AJqhJv7VLSrACfiC8TdooBsa2qitA7qCOF12XgpHQzAJCvs1ryhEwmgnB3a5_aNW-5_s3REmAvmaA587Au0C-vBlRFvymrYRAITUN0Vb9z0giBAu82GcEaRuTvXblYeQXz")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxES512, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with HS256 (JSX)" do
    {:ok, token} = Joken.Token.encode(@jsx_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.Token.decode(@jsx_json_module, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with HS384 (JSX)" do
    defmodule TestJsxHS384 do
      use BaseConfig

      def algorithm(), do: :HS384

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxHS384, @payload)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxHS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with HS512 (JSX)" do

    defmodule TestJsxHS512 do
      use BaseConfig

      def algorithm(), do: :HS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxHS512, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxHS512, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS256 (JSX)" do

    defmodule TestJsxPS256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS256

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxPS256, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.s-2hYCN-GpKbaJpTByhOfdGQE2yWa8wZR9y4w9c1xh5IlCothIvSiF4MMPWGYqf7mOYRij_pftsd3s0AjDCZBTPOua8o9_yJlI_ohfly-HAvZ3vRYEL126zOQ-vQWoZI_nmDjzjCBkYTElzi6RC6R8FyE7SpVR6btFixcOjqsbs1y8to60NE5bYgiBXkT1BA2ADGY3QLxCWvmrFkyRtfWaBmB74iHQSDat0k9T0A8z43M9CG29UhyhnwEwR938OFRdMyWMqREh4IoIIjn-UYAQ0IcHK3TiqZHB05X_ZZ6VZh3szmlKMebzucN85rCYXai6eGvKFIERrwBKkxhSNDeg")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS256, "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.s-2hYCN-GpKbaJpTByhOfdGQE2yWa8wZR9y4w9c1xh5IlCothIvSiF4MMPWGYqf7mOYRij_pftsd3s0AjDCZBTPOua8o9_yJlI_ohfly-HAvZ3vRYEL126zOQ-vQWoZI_nmDjzjCBkYTElzi6RC6R8FyE7SpVR6btFixcOjqsbs1y8to60NE5bYgiBXkT1BA2ADGY3QLxCWvmrFkyRtfWaBmB74iHQSDat0k9T0A8z43M9CG29UhyhnwEwR938OFRdMyWMqREh4IoIIjn-UYAQ0IcHK3TiqZHB05X_ZZ6VZh3szmlKMebzucN85rCYXai6eGvKFIERrwBKkxhSNDeg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS384 (JSX)" do

    defmodule TestJsxPS384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS384

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxPS384, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.Pgc1QLw5k6-SbqkYq1MHHtm1MRJ3OUicueG-7CuufED06aRzWGbM6bdY0WxknGEUyH4VBe3_9y8hc-s77uLXhgkJIttmkXDWSLOcE7_BmbEe91848nbaAPZS0aKxJXHkAgx6CrLkVMQrKytwECtnWW-cz8mu1iOv5teZNc8UywzflssAQfaSWoBSUvGL5TEfDQWkftBiidkACA0K9Epdk0pZk1qRpAgw11YW5C3Dybrxp8M_osctfHfDHOxF5WUyS_sGiPwYRHU2R3-eFNlcE15NTf24Jp5pcuM3JP41OGm4aZiA2QhDhyAOtzWmJSNuKN0XaCiSnEuUvwbkPpRSPg")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS384, "eyJhbGciOiJQUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.Pgc1QLw5k6-SbqkYq1MHHtm1MRJ3OUicueG-7CuufED06aRzWGbM6bdY0WxknGEUyH4VBe3_9y8hc-s77uLXhgkJIttmkXDWSLOcE7_BmbEe91848nbaAPZS0aKxJXHkAgx6CrLkVMQrKytwECtnWW-cz8mu1iOv5teZNc8UywzflssAQfaSWoBSUvGL5TEfDQWkftBiidkACA0K9Epdk0pZk1qRpAgw11YW5C3Dybrxp8M_osctfHfDHOxF5WUyS_sGiPwYRHU2R3-eFNlcE15NTf24Jp5pcuM3JP41OGm4aZiA2QhDhyAOtzWmJSNuKN0XaCiSnEuUvwbkPpRSPg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with PS512 (JSX)" do

    defmodule TestJsxPS512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :PS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxPS512, @payload)
    # token will be different every time, so verify static token
    # assert(token == "eyJhbGciOiJQUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.GWrtPFuCQhrlfq_iCDqXkl95AwtuRTU5KaMbIW3s1By4dvwpV5lCIG5atm53eHSTxPm4__Ms9yNdUdu9DWVZLMoP39EiXozgnd7VskWhv9CB3ATo5TNpBuGKnricZGcXMg0J8_3q6a5wZZ5U0W2rynpKQFU0iRqXZlw5xdlTU6GPSOttTfGr1lu8tt484xlS5r5oW46cdwerXmAfQuTNq8xaMFud7Ssj8iGpEE1CkR1IGRySxppcn8-QoyI1JOmNlIn-7610nyMkLfiZs8lrVZqdf_1Lp368vxYK6s-_rtF_TlIItfGmrNro6wEwxfJHm-OIhlKSIWKjVyMk-obJrg")
    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS512, "eyJhbGciOiJQUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.GWrtPFuCQhrlfq_iCDqXkl95AwtuRTU5KaMbIW3s1By4dvwpV5lCIG5atm53eHSTxPm4__Ms9yNdUdu9DWVZLMoP39EiXozgnd7VskWhv9CB3ATo5TNpBuGKnricZGcXMg0J8_3q6a5wZZ5U0W2rynpKQFU0iRqXZlw5xdlTU6GPSOttTfGr1lu8tt484xlS5r5oW46cdwerXmAfQuTNq8xaMFud7Ssj8iGpEE1CkR1IGRySxppcn8-QoyI1JOmNlIn-7610nyMkLfiZs8lrVZqdf_1Lp368vxYK6s-_rtF_TlIItfGmrNro6wEwxfJHm-OIhlKSIWKjVyMk-obJrg")
    assert(@payload == decoded_payload)

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxPS512, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS256 (JSX)" do

    defmodule TestJsxRS256 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS256

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxRS256, @payload)
    assert(token == "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.e3hyn_oaaA2lxMlqH1UPo8STN-a_sszl8B2_s6tY9aT_YBAmfd7BXJOPsOMl7x2wXeKMQaNBVjna2tA0UiO_m3SpwiYgoTcU65D6OgkzugmLD_DhjDK1YCOKlm7So1uhbkb_QCuo4Ij5scsQqwv7hkxo4IximGBeH9LAvPhPTaGmYJMI7_tWIld2TlY6tNUQP4n0qctXsI3hjvGzdvuQW-tRnzAQCC4TYe-mJgFa033NSHeiX-sZB-SuYlWi7DJqDTiwlb_beVdqWpxxtFDA005Iw6FZTpH9Rs1LVwJU5t3RN5iWB-z4ZI-kKsGUGLNrAZ7btV6Ow2FMAdj9TXmNpQ")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxRS256, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS384 (JSX)" do

    defmodule TestJsxRS384 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS384

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxRS384, @payload)
    assert(token == "eyJhbGciOiJSUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.XpXgnjgYH-SIQMPg8xnNXXG5RV6CQhWajHoJbf44_fT70ZbpVDSeQopNXjQg3ClFDdbTbyGeR-cCfgr1xMqdWWpbmuCn13CS9-918WD0fENkrDMb_ErFyft0XiWTLeQlW_BaLP0-sqAfY8-XsiDMbClP2hgAdyV9iA-aFJ2S5HVKI_j68WmjcvwNGPNJcfhTEpx0mMroBj1qNBRNS5p94L-QRieZgtbs5ikrn7OAo5NME6DGtrDLd1deeN84r3nGTqQODiK22o-LSjnpWHKw0iXjQymFrnnd7B_IgYiWu7X4ZPmUy_wMSYT9O8k00sfE_VRVV5Uq2qlNpCYWv9LlLA")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxRS384, token)
    assert(@payload == decoded_payload)
  end

  test "encode and decode with RS512 (JSX)" do

    defmodule TestJsxRS512 do
      use BaseConfig

      def secret_key(), do: BaseConfig.rsa_key
      def algorithm(), do: :RS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsxRS512, @payload)
    assert(token == "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.aw9j2S7aqohX_dGWJYrA1btgQE46Dtiy-7S9J70-k_Tm2ElepqgAj25gBDqLWkGuhKKncHWlablS2fLpmzmh-FqPbamBms6Wb9oL73H-BN4RbaCV_GGtqRFJGGHiMcKMTkbAqFps0P9xyAlr77mjplC8yXvS-gnRw3Y1z3vpgmju9G7DSyKYNUea0-_7VkT-dq0DQTiAxpaBNz4bV4Ycuduu4J24opTAGnZKR3QMdLJnoM1NRhCtpAo8twXi5He4yIFiCoz5Cjy6uWkY8mtJchC5BEES-EnbqsTBY8ScOH3tQuR9gFxunHGrfwOvT6OgX2Y5D-ZjVC6WuFGy9tPb7w")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsxRS512, token)
    assert(@payload == decoded_payload)
  end

  test "missing signature" do

    defmodule TestJsx512Missing do
      use BaseConfig

      def algorithm(), do: :HS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsx512Missing, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:error, message} = Joken.Token.decode(TestJsx512Missing, "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ") 
    assert("Missing signature" == message) 
  end

  test "unsecure token" do
    defmodule TestJsxNone do
      use BaseConfig

      def algorithm(), do: :none

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {status, message} = Joken.Token.decode(TestJsxNone, "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ")
    assert(status == :error)
    assert(message == "Missing signature")
  end

  test "decode token generated with un-sorted keys (JSX)" do
    {:ok, _} = Joken.Token.encode(@jsx_json_module, @payload)
    {:ok, decoded_payload} = Joken.Token.decode(@jsx_json_module, @unsorted_header_token)
    assert(@payload == decoded_payload)
  end

  test "signature validation (JSX)" do
    {:ok, token} = Joken.Token.encode(@jsx_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")
    {:ok, _} = Joken.Token.decode(@jsx_json_module, token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.Token.decode(@jsx_json_module, new_token)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)" do
    defmodule ExpSuccessTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "exp", "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _, _), do: :ok
    end

    defmodule ExpFailureTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "exp", "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _, _), do: :ok
    end 

    {:ok, token} = Joken.Token.encode(ExpSuccessTest,  %{ "name" => "John Doe" })
    {status, _} = Joken.Token.decode(ExpSuccessTest, token)
    assert(status == :ok)

    {:ok, token} = Joken.Token.encode(ExpFailureTest, %{ "name" => "John Doe" })
    {status, mesg} = Joken.Token.decode(ExpFailureTest, token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "valid iat claim" do

    defmodule IatSuccessTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:iat, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _), do: nil

      def validate_claim(:iat, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "iat", "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _, _), do: :ok
    end

    defmodule IatFailureTest do
      use BaseConfig
      require Logger

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:iat, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _), do: nil

      def validate_claim(:iat, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "iat", "Token not valid yet", &(&1 < &2))
      end

      def validate_claim(_, _, _), do: :ok
    end 

    {:ok, token} = Joken.Token.encode(IatSuccessTest,  %{ "name" => "John Doe" })
    assert {:ok, _} = Joken.Token.decode(IatSuccessTest, token)

    {:ok, token} = Joken.Token.encode(IatFailureTest,  %{ "name" => "John Doe" })
    assert {:error, "Token not valid yet"} == Joken.Token.decode(IatFailureTest, token)
  end
end
