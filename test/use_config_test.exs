defmodule Joken.UseConfig.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Joken.CurrentTime.Mock
  alias Joken.Signer

  setup do
    {:ok, _pid} = start_supervised(Mock)
    :ok
  end

  describe "__MODULE__.generate_and_sign" do
    test "can use default signer configuration" do
      defmodule DefaultSignerConfig do
        use Joken.Config

        def token_config, do: %{}
      end

      assert DefaultSignerConfig.generate_and_sign() ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.mwiDnq8rTFp5Oyy5i7pT8qktTB4tZOAfiJXTEbEqn2g",
                %{}}
    end

    test "can override default signer callback" do
      defmodule OverrideDefaultSignerConfig do
        use Joken.Config

        def token_config, do: %{}
        def default_signer, do: Joken.Signer.create("HS256", "s3cret")
      end

      assert OverrideDefaultSignerConfig.generate_and_sign() ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.JXJ_RWHq_C9ZJbkrRGRg7NxSFm2hnVu5ToEa8Nx6OiU",
                %{}}
    end

    test "can pass specific signer" do
      defmodule SpecificSignerConfig do
        use Joken.Config, default_signer: :hs256

        def token_config, do: %{}
      end

      assert SpecificSignerConfig.generate_and_sign() ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.P4Lqll22jQQJ1eMJikvNg5HKG-cKB0hUZA9BZFIG7Jk",
                %{}}
    end

    test "can pass a `Joken.Signer` instance" do
      defmodule SignerInstanceConfig do
        use Joken.Config

        def token_config, do: %{}
      end

      signer = Joken.Signer.create("HS256", "s3cret")

      assert SignerInstanceConfig.generate_and_sign(%{}, signer) ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.JXJ_RWHq_C9ZJbkrRGRg7NxSFm2hnVu5ToEa8Nx6OiU",
                %{}}
    end

    test "can receive extra claims" do
      defmodule ExtraClaimsConfig do
        use Joken.Config

        def token_config, do: %{}
      end

      assert ExtraClaimsConfig.generate_and_sign(%{"name" => "John Doe"}) ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YSy8oSoFcYMXK2Gn2vcdsSRGtxnYHQ1KGeVOHO_tSbc",
                %{"name" => "John Doe"}}
    end
  end

  describe "__MODULE__.verify_and_validate" do
    test "can verify and validate a generated token" do
      defmodule(SimpleVerifyAndValidate, do: use(Joken.Config))

      jwt = SimpleVerifyAndValidate.generate_and_sign!()

      assert {:ok, _claims} = SimpleVerifyAndValidate.verify_and_validate(jwt)
    end

    test "can validate a token with a context" do
      defmodule ValidateWithContext do
        use Joken.Config

        def token_config do
          %{}
          # Validate function with arity 2
          |> add_claim("custom", fn -> "custom" end, fn val, _claims, ctx -> val == ctx.custom end)
        end
      end

      jwt = ValidateWithContext.generate_and_sign!()

      assert {:ok, %{"custom" => "custom"}} =
               ValidateWithContext.verify_and_validate(
                 jwt,
                 ValidateWithContext.default_signer(),
                 %{custom: "custom"}
               )
    end

    test "can validate a token with a signer generated only with the public key" do
      defmodule OnlyPublicKeyValidate do
        use Joken.Config

        def token_config, do: %{}
      end

      # Private signer generates
      private_pem = Application.get_env(:joken, :pem_rs256)[:key_pem]
      private_signer = Signer.create("RS256", %{"pem" => private_pem})

      assert token = OnlyPublicKeyValidate.generate_and_sign!(%{}, private_signer)

      # Public signer validates
      public_pem = Application.get_env(:joken, :public_pem)[:key_pem]
      public_signer = Signer.create("RS256", %{"pem" => public_pem})

      assert OnlyPublicKeyValidate.verify_and_validate(token, public_signer) == {:ok, %{}}
    end

    test "can pass a `Joken.Signer` instance" do
      defmodule ValidateWithSigner do
        use Joken.Config

        def token_config, do: %{}
      end

      token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.JXJ_RWHq_C9ZJbkrRGRg7NxSFm2hnVu5ToEa8Nx6OiU"

      signer = Joken.Signer.create("HS256", "s3cret")

      assert ValidateWithSigner.verify_and_validate(token, signer) == {:ok, %{}}
    end
  end

  describe "__MODULE__.verify_and_validate!" do
    test "can verify and validate a generated token" do
      defmodule(SimpleVerifyAndValidateRaise, do: use(Joken.Config))

      jwt = SimpleVerifyAndValidateRaise.generate_and_sign!()

      assert %{} = SimpleVerifyAndValidateRaise.verify_and_validate!(jwt)
    end

    test "can validate a token with a context" do
      defmodule ValidateWithContextRaise do
        use Joken.Config

        def token_config do
          %{}
          # Validate function with arity 2
          |> add_claim("custom", fn -> "custom" end, fn val, _claims, ctx -> val == ctx.custom end)
        end
      end

      jwt = ValidateWithContextRaise.generate_and_sign!()

      assert %{"custom" => "custom"} =
               ValidateWithContextRaise.verify_and_validate!(
                 jwt,
                 ValidateWithContextRaise.default_signer(),
                 %{custom: "custom"}
               )
    end

    test "can pass a `Joken.Signer` instance" do
      defmodule ValidateWithSignerRaise do
        use Joken.Config

        def token_config, do: %{}
      end

      token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.JXJ_RWHq_C9ZJbkrRGRg7NxSFm2hnVu5ToEa8Nx6OiU"

      signer = Joken.Signer.create("HS256", "s3cret")

      assert ValidateWithSignerRaise.verify_and_validate!(token, signer) == %{}
    end
  end
end
