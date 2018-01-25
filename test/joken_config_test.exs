defmodule Joken.Config.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Joken.{Config, CurrentTime.Mock}

  setup do
    Mock.start_link()

    name = Mock.unique_name_per_process()
    on_exit(fn -> IO.puts("Mock test process: #{inspect(Process.whereis(name))}") end)
    :ok
  end

  describe "Joken.Config.default_claims/1" do
    test "generates exp, iss, iat, nbf claims" do
      assert Config.default_claims() |> Map.keys() == ["exp", "iat", "iss", "nbf"]
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
      assert keys == ["iat", "iss", "nbf"]

      keys = Config.default_claims(skip: [:exp, :iat]) |> Map.keys()
      assert keys == ["iss", "nbf"]

      assert Config.default_claims(skip: [:exp, :iat, :iss, :nbf]) == %{}
    end

    test "can set a different issuer" do
      assert Config.default_claims(iss: "Custom")["iss"].generate.() == "Custom"
    end

    test "default exp validates properly" do
      Mock.freeze()

      exp_claim = Config.default_claims()["exp"]
      # 1 second expiration
      assert exp_claim.validate.(Joken.current_time() + 1)

      # -1 second expiration (always expired)
      refute exp_claim.validate.(Joken.current_time() - 1)

      # 0 second expiration (always expired)
      refute exp_claim.validate.(Joken.current_time())
    end

    test "default iss validates properly" do
      exp_claim = Config.default_claims()["iss"]
      assert exp_claim.validate.("Joken")
      refute exp_claim.validate.("Another")
    end

    property "any given issuer will be validated" do
      check all issuer <- binary() do
        iss_claim = Config.default_claims(iss: issuer)["iss"]
        assert iss_claim.validate.(issuer)
      end
    end

    test "default nbf validates properly" do
      Mock.freeze()
      exp_claim = Config.default_claims()["nbf"]

      # Not before current time
      assert exp_claim.validate.(Joken.current_time())

      # not before a second ago
      assert exp_claim.validate.(Joken.current_time() - 1)

      # not before a second in the future
      refute exp_claim.validate.(Joken.current_time() + 1)
    end
  end
end
