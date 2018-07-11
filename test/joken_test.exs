defmodule JokenTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  import Joken.Config, only: [add_claim: 4, default_claims: 1]
  alias Joken.CurrentTime.Mock

  setup do
    {:ok, _pid} = start_supervised(Mock)
    :ok
  end

  defmodule EmptyToken do
    use Joken.Config

    def token_config, do: %{}
  end

  describe "token introspection" do
    test "can peek header" do
      jwt = EmptyToken.generate_and_sign!()
      assert Joken.peek_header(jwt) == %{"typ" => "JWT", "alg" => "HS256"}
    end

    test "can peek body" do
      custom_claims = %{"my" => "claim"}
      jwt = EmptyToken.generate_and_sign!(custom_claims)
      assert Joken.peek_claims(jwt) == custom_claims
    end
  end

  describe "signer key" do
    test "can verify a jwt with a signer key" do
      jwt = EmptyToken.generate_and_sign!()

      assert {:ok, %{}} == Joken.verify(jwt, :default_signer)
    end

    test "can sign a jwt with a signer key" do
      assert Joken.encode_and_sign(%{}, :default_signer) ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.mwiDnq8rTFp5Oyy5i7pT8qktTB4tZOAfiJXTEbEqn2g",
                %{}}
    end

    test "raises when signer key does not exist" do
      assert_raise Joken.Error,
                   Joken.Error.message(%Joken.Error{reason: :no_default_signer}),
                   fn ->
                     Joken.encode_and_sign(%{}, :non_existent_signer)
                   end
    end
  end

  describe "claim validation" do
    test "debug message is shown when claim validation fails" do
      token_config = default_claims(skip: [:exp, :nbf, :iat, :jti, :aud])

      validate_fun = fn ->
        assert {:error, [message: "Invalid token", claim: "iss", claim_val: "someone"]} ==
                 Joken.validate(token_config, %{"iss" => "someone"}, %{})
      end

      assert capture_log(validate_fun) =~
               "Claim %{\"iss\" => \"someone\"} did not pass validation.\n\nCurrent time: "
    end

    test "can make multi claim validation" do
      token_config = %{} |> add_claim("claim1", nil, &(&1 == &2["claim2"]))

      assert {:ok, %{"claim2" => "value", "claim1" => "value"}} ==
               Joken.validate(token_config, %{"claim2" => "value", "claim1" => "value"}, %{})
    end
  end
end
