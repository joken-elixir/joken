defmodule HS256Auth do
  use Joken.Config, default_key: :hs256
end

defmodule HS384Auth do
  use Joken.Config, default_key: :hs384
end

defmodule HS512Auth do
  use Joken.Config, default_key: :hs512
end

defmodule HS256AuthVerify do
  use Joken.Config, default_key: :hs256

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

defmodule HS384AuthVerify do
  use Joken.Config, default_key: :hs384

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

defmodule HS512AuthVerify do
  use Joken.Config, default_key: :hs512

  def token_config do
    %{}
    |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
    |> add_claim("test", fn -> true end, &(&1 == true))
    |> add_claim("age", fn -> 666 end, &(&1 > 18))
    |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
  end
end

hs256_token =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.AxM6-iOez0tM35N6hSxr_LWe9LC28c4MeoRvEIi4Gtw"

hs384_token =
  "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.35wYGZk5Dzka_BMzeplo9sz0q_BDwg_C2m-_xqp-6RBVU7qyhudAwy8hFY1Dxti_"

hs512_token =
  "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhZ2UiOjY2NiwibmFtZSI6IkpvaG4gRG9lIiwic2ltcGxlIHRpbWUgdGVzdCI6MSwidGVzdCI6dHJ1ZX0.P7Og_ODvM94PPXettTtalgiGtxwj7oBoDk_4zj08o3kRZPQCDqNy4lHanoEhY-CTS-CPbJKivelnxMGBJ-3x5A"

Benchee.run(
  %{
    "HS256 generate and sign" => fn -> HS256Auth.generate_and_sign() end,
    "HS384 generate and sign" => fn -> HS384Auth.generate_and_sign() end,
    "HS512 generate and sign" => fn -> HS512Auth.generate_and_sign() end
  },
  time: 5
)

Benchee.run(
  %{
    "HS256 verify and validate" => fn -> HS256AuthVerify.verify_and_validate(hs256_token) end,
    "HS384 verify and validate" => fn -> HS384AuthVerify.verify_and_validate(hs384_token) end,
    "HS512 verify and validate" => fn -> HS512AuthVerify.verify_and_validate(hs512_token) end
  },
  time: 5
)
