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
      token_config =
        %{}
        |> add_claim("iss", fn -> "not someone" end, fn val ->
          val == "not someone"
        end)

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

  describe "error" do
    test "is raised when generate_and_sign! returns error" do
      defmodule BadBeforeGenerate do
        use Joken.Hooks

        @impl true
        def before_generate(_opts, _status, _extra_claims, _token_config),
          do: {:halt, {:error, :my_reason}}
      end

      assert_raise(
        Joken.Error,
        "Error while calling `generate_and_sign!`. Reason: :my_reason.\n",
        fn ->
          Joken.generate_and_sign!(nil, nil, nil, [BadBeforeGenerate])
        end
      )
    end

    test "is raised when verify_and_validate! returns error" do
      defmodule BadBeforeVerify do
        use Joken.Hooks

        @impl true
        def before_verify(_opts, _status, _token, _signer),
          do: {:halt, {:error, :my_reason}}
      end

      assert_raise(
        Joken.Error,
        "Error while calling `verify_and_validate!`. Reason: :my_reason.\n",
        fn ->
          Joken.verify_and_validate!(nil, "", nil, nil, [BadBeforeVerify])
        end
      )
    end
  end

  test "can expand a proper token" do
    {:ok, jwt, _} =
      Joken.encode_and_sign(%{}, Joken.Signer.create("HS256", "secret", %{"kid" => "my_id"}))

    assert {:ok, %{"protected" => h, "payload" => p, "signature" => s}} = Joken.expand(jwt)
  end

  test "returns error while trying to expand malformed token" do
    assert {:error, :token_malformed} == Joken.expand("asd")
  end
end
