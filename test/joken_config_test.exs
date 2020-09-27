defmodule Joken.Config.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Joken.{Config, CurrentTime.Mock, Error}

  setup do
    {:ok, _pid} = start_supervised(Mock)
    :ok
  end

  describe "Joken.Config.default_claims/1" do
    property "any given issuer will be validated" do
      check all(issuer <- binary()) do
        iss_claim = Config.default_claims(iss: issuer)["iss"]
        assert iss_claim.validate.(issuer, %{}, %{})
      end
    end

    property "any given audience will be validated" do
      check all(audience <- binary()) do
        aud_claim = Config.default_claims(aud: audience)["aud"]
        assert aud_claim.validate.(audience, %{}, %{})
      end
    end

    test "generates exp, iss, iat, nbf claims" do
      assert Config.default_claims() |> Map.keys() == ["aud", "exp", "iat", "iss", "jti", "nbf"]
    end

    test "can customize exp duration" do
      Mock.freeze()

      # 1 second
      exp_claim = Config.default_claims(default_exp: 1)["exp"]
      assert exp_claim.generate.() > Joken.current_time()

      # Zero seconds
      exp_claim = Config.default_claims(default_exp: 0)["exp"]
      assert exp_claim.generate.() <= Joken.current_time()
    end

    test "can skip claims" do
      keys = Config.default_claims(skip: [:exp]) |> Map.keys()
      assert keys == ["aud", "iat", "iss", "jti", "nbf"]

      keys = Config.default_claims(skip: [:exp, :iat]) |> Map.keys()
      assert keys == ["aud", "iss", "jti", "nbf"]

      assert Config.default_claims(skip: [:aud, :exp, :iat, :iss, :jti, :nbf]) == %{}
    end

    test "defaults audience and issuer to Joken" do
      claims = Config.default_claims()
      assert claims["aud"].generate.() == "Joken"
      assert claims["iss"].generate.() == "Joken"
    end

    test "can set a different audience and issuer" do
      claims = Config.default_claims(aud: "aud", iss: "iss")
      assert claims["aud"].generate.() == "aud"
      assert claims["iss"].generate.() == "iss"
    end

    test "default exp validates properly" do
      Mock.freeze()

      exp_claim = Config.default_claims()["exp"]
      # 1 second expiration
      assert exp_claim.validate.(Joken.current_time() + 1, %{}, %{})

      # -1 second expiration (always expired)
      refute exp_claim.validate.(Joken.current_time() - 1, %{}, %{})

      # 0 second expiration (always expired)
      refute exp_claim.validate.(Joken.current_time(), %{}, %{})
    end

    test "default iss validates properly" do
      exp_claim = Config.default_claims()["iss"]
      assert exp_claim.validate.("Joken", %{}, %{})
      refute exp_claim.validate.("Another", %{}, %{})
    end

    test "default nbf validates properly" do
      Mock.freeze()
      exp_claim = Config.default_claims()["nbf"]

      # Not before current time
      assert exp_claim.validate.(Joken.current_time(), %{}, %{})

      # not before a second ago
      assert exp_claim.validate.(Joken.current_time() - 1, %{}, %{})

      # not before a second in the future
      refute exp_claim.validate.(Joken.current_time() + 1, %{}, %{})
    end

    test "can switch default jti generation function" do
      jti_claim = Config.default_claims(generate_jti: fn -> "Hi" end)["jti"]

      assert jti_claim.generate.() == "Hi"
    end

    test "raises with invalid data types" do
      raise_fun = fn -> Config.default_claims(generate_jti: 123) end
      assert_raise Error, Error.message(%Error{reason: :invalid_default_claims}), raise_fun
    end
  end

  describe "add_claim" do
    test "must provide a validate function or a generate function" do
      assert_raise Error, Error.message(%Error{reason: :claim_configuration_not_valid}), fn ->
        Joken.Config.add_claim(%{}, "claim_key", nil, nil, [])
      end
    end

    test "validate_function must be of arity 1 or 2" do
      assert_raise Error, Error.message(%Error{reason: :bad_validate_fun_arity}), fn ->
        Joken.Config.add_claim(
          %{},
          "claim_key",
          nil,
          fn _arg1, _arg2, _arg3, _arg4 -> true end,
          []
        )
      end
    end
  end

  describe "generate_and_sign/verify_and_update" do
    property "should always pass for the same signer" do
      generator =
        StreamData.map_of(
          StreamData.string(:ascii),
          StreamData.one_of([
            StreamData.string(:ascii),
            StreamData.integer(),
            StreamData.boolean(),
            StreamData.map_of(
              StreamData.string(:ascii),
              StreamData.one_of([
                StreamData.string(:ascii),
                StreamData.integer(),
                StreamData.boolean()
              ])
            )
          ])
        )

      defmodule PropertyEncodeDecode do
        use Joken.Config
      end

      check all(input_map <- generator) do
        {:ok, token, gen_claims} = PropertyEncodeDecode.generate_and_sign(input_map)
        {:ok, claims} = PropertyEncodeDecode.verify_and_validate(token)

        assert claims == gen_claims
        assert_map_contains_other(claims, input_map)
      end
    end
  end

  defp assert_map_contains_other(target, contains_map) do
    contains_map
    |> Enum.each(fn
      {"", _val} ->
        :ok

      {key, value} ->
        result = Map.fetch(target, key)

        case result do
          {:ok, cur_value} when value == cur_value ->
            :ok

          {:ok, cur_value} when value != cur_value ->
            raise """
            Value for key #{key} differs.

            Expected: #{inspect(value)}
            Got:      #{inspect(cur_value)}
            """

          val ->
            raise """
            Expected value differs.

            Got: #{inspect(val)}.
            """
        end
    end)
  end
end
