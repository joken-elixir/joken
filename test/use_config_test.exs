defmodule Joken.UseConfig.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Joken.CurrentTime.Mock

  setup do
    start_supervised!(Mock)
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
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.mwiDnq8rTFp5Oyy5i7pT8qktTB4tZOAfiJXTEbEqn2g"}
    end

    test "can pass specific signer" do
      defmodule SpecificSignerConfig do
        use Joken.Config, default_signer: :hs256

        def token_config, do: %{}
      end

      assert SpecificSignerConfig.generate_and_sign() ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.P4Lqll22jQQJ1eMJikvNg5HKG-cKB0hUZA9BZFIG7Jk"}
    end

    test "can pass a `Joken.Signer` instance" do
      defmodule SignerInstanceConfig do
        use Joken.Config

        def token_config, do: %{}
      end

      signer = Joken.Signer.create("HS256", "s3cret")

      assert SignerInstanceConfig.generate_and_sign(%{}, signer) ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.JXJ_RWHq_C9ZJbkrRGRg7NxSFm2hnVu5ToEa8Nx6OiU"}
    end

    test "can receive extra claims" do
      defmodule ExtraClaimsConfig do
        use Joken.Config

        def token_config, do: %{}
      end

      assert ExtraClaimsConfig.generate_and_sign(%{"name" => "John Doe"}) ==
               {:ok,
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YSy8oSoFcYMXK2Gn2vcdsSRGtxnYHQ1KGeVOHO_tSbc"}
    end
  end
end
