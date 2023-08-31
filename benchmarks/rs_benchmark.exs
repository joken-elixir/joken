defmodule RS256Auth do
  use Joken.Config, default_signer: :rs256
end

defmodule RS384Auth do
  use Joken.Config, default_signer: :rs384
end

defmodule RS512Auth do
  use Joken.Config, default_signer: :rs512
end

defmodule RS256AuthVerify do
  use Joken.Config, default_signer: :rs256

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

defmodule RS384AuthVerify do
  use Joken.Config, default_signer: :rs384

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

defmodule RS512AuthVerify do
  use Joken.Config, default_signer: :rs512

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

rs256_token =
  "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.koLkuRCtAvWrEsrRDtWeiwJiRsEhaZxWexxrM-qiEh-1U-6fnLw9AY3qoO5Pb7UiUO1GviAateM8QkvKtv1VnIfzr0kZWx9rHJmVeTXhp9RtA24l1gn2vfi-6Q5eXmvk--AMhUNF3JdG35eKGbLNc3RMMyH0gj8Q4KNPeQKVnKErKRa8mLIBWdi-LXrCfhVbRJdhMQNI_jJ3I04EJ0ZsqjNXHGOepaNQ_MDYc306nXsfbMyIa90jnnNhYtLMofWCY8S3eqOW-SKoRZw5ztBIJIomLnYEon7sipolGOcJA_t7E4vmqaOP3pdg_n_Afsa0OGfXEZ5fIfBqTSQ_ivlr4Q"

rs384_token =
  "eyJhbGciOiJSUzM4NCIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.M3RObqG5KnbuxJvqOrvve63zEdQFqBIERBUzKc0Ibz0VmVDjJfEI7MiNxktV7KwNNYzL3SVAVQN44I6uIiltMIQgeJgo5WKBdV4j1IUIqYf43iiqBt4CjCuMSOAFsGQjftHA5VdfMmoIFAkT29ImPokN7oJsMnmuPK3HIaKcMjcuG0z0m938nA85nwi1-wPbPUYPOJmt77Dwllp7mrBoZj_siLkURcHLUL45IlA-22MuqkJccMhW8FtHurGPOub0d9EH3TO0Ge5E3o78k33rPHpJVAWxHYw7-Yypsf1CrObuSB1MDXA69USLateG9mcRJVoxKCpLzSFI6V5gvO58MQ"

rs512_token =
  "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.iGIyevqNEl_Mb6Ijm5PcA5_-xBk_NMzKAq_O6ZuNfKS9IVLO5pt46FiQ27oYBzCXUBORSHVJhkkhODLRoiYYlzMerL14WG8yUpVh1W3PjPJhxdg2YhBGySHnLSUMvyMM0mLKoslQd5arOOJCvmOkocpFOk-3U2rmjYOLDngqBAiXtnI12xP-uWrLIsWd3_B9TKSBmXGlBrkEUsDv2yBNlpmi4q-W1BK6VPS2_VHc2I4dZS1FDrWsrGb6RUijhBwo91sBcW2LKxm0Y_TIKnhT8OVWt_dfI2Lk_KtRVr9Ra0i4XN-H1zEX1Dg7ViVnh1NNsyIzi2WKmCMz6m1P2ocTjA"

Benchee.run(
  %{
    "RS256 generate and sign" => fn -> RS256Auth.generate_and_sign() end,
    "RS384 generate and sign" => fn -> RS384Auth.generate_and_sign() end,
    "RS512 generate and sign" => fn -> RS512Auth.generate_and_sign() end
  },
  time: 5
)

Benchee.run(
  %{
    "RS256 verify and validate" => fn -> RS256AuthVerify.verify_and_validate(rs256_token) end,
    "RS384 verify and validate" => fn -> RS384AuthVerify.verify_and_validate(rs384_token) end,
    "RS512 verify and validate" => fn -> RS512AuthVerify.verify_and_validate(rs512_token) end
  },
  time: 5
)
