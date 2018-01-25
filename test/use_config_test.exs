defmodule Joken.UseConfig.Test do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Joken.CurrentTime.Mock

  setup do
    Mock.start_link()
    :ok
  end

  describe "__MODULE__.generate_and_sign" do
    test "can use default signer configuration" do
      defmodule DefaultConfig do
        use Joken.Config, claims_config: %{}
      end

      assert DefaultConfig.generate_and_sign() ==
               "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.mwiDnq8rTFp5Oyy5i7pT8qktTB4tZOAfiJXTEbEqn2g"
    end

    test "can pass specific signer" do
      defmodule DefaultConfig do
        use Joken.Config, claims_config: %{}, default_key: :hs256
      end

      assert DefaultConfig.generate_and_sign() ==
               "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.P4Lqll22jQQJ1eMJikvNg5HKG-cKB0hUZA9BZFIG7Jk"
    end

    test "can receive extra claims" do
      defmodule DefaultConfig do
        use Joken.Config, claims_config: %{}
      end

      assert DefaultConfig.generate_and_sign(%{"name" => "John Doe"}) ==
               "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YSy8oSoFcYMXK2Gn2vcdsSRGtxnYHQ1KGeVOHO_tSbc"
    end
  end
end
