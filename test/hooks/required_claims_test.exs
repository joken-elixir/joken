defmodule Joken.Hooks.RequiredClaimsTest do
  use ExUnit.Case, async: true

  test "fails if required claim is missing - list of binaries" do
    alias MissingRequiredClaimAsListOfBinaries, as: Config

    defmodule MissingRequiredClaimAsListOfBinaries do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, ["claim1", "claim2"]

      def token_config, do: %{}
    end

    assert {:error, [message: "Invalid token", missing_claims: ["claim2"]]} ==
             %{claim1: 1, claim3: 3}
             |> Config.generate_and_sign!()
             |> Config.verify_and_validate()
  end

  test "succeeds if required claim is present - list of binaries" do
    alias RequiredClaimPresentAsListOfBinaries, as: Config

    defmodule RequiredClaimPresentAsListOfBinaries do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, ["claim1", "claim2"]

      def token_config, do: %{}
    end

    assert {:ok, %{"claim1" => 1, "claim2" => 2, "claim3" => 3}} ==
             %{claim1: 1, claim2: 2, claim3: 3}
             |> Config.generate_and_sign!()
             |> Config.verify_and_validate()
  end

  test "fails if required claim is missing - list of atoms" do
    alias MissingRequiredClaimAsListOfAtoms, as: Config

    defmodule MissingRequiredClaimAsListOfAtoms do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:claim1, :claim2]

      def token_config, do: %{}
    end

    assert {:error, [message: "Invalid token", missing_claims: ["claim2"]]} ==
             %{claim1: 1, claim3: 3}
             |> Config.generate_and_sign!()
             |> Config.verify_and_validate()
  end

  test "succeeds if required claim is present - list of atoms" do
    alias RequiredClaimPresentAsListOfAtoms, as: Config

    defmodule RequiredClaimPresentAsListOfAtoms do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:claim1, :claim2]

      def token_config, do: %{}
    end

    assert {:ok, %{"claim1" => 1, "claim2" => 2, "claim3" => 3}} ==
             %{claim1: 1, claim2: 2, claim3: 3}
             |> Config.generate_and_sign!()
             |> Config.verify_and_validate()
  end

  test "raises if missing options" do
    alias MissingRequiredClaimsOptions, as: Config

    defmodule MissingRequiredClaimsOptions do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims

      def token_config, do: %{}
    end

    assert_raise RuntimeError, "Missing required claims options", fn ->
      %{claim1: 1, claim2: 2, claim3: 3}
      |> Config.generate_and_sign!()
      |> Config.verify_and_validate()
    end
  end

  test "raises if options are not a list" do
    alias MissingRequiredClaimsOptionsNotAList, as: Config

    defmodule MissingRequiredClaimsOptionsNotAList do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, :my_option

      def token_config, do: %{}
    end

    assert_raise RuntimeError, "Options must be a list of claim keys", fn ->
      %{claim1: 1, claim2: 2, claim3: 3}
      |> Config.generate_and_sign!()
      |> Config.verify_and_validate()
    end
  end

  test "raises if any of the keys is not an atom or string" do
    alias BadRequiredClaimsKeyOption, as: Config

    defmodule BadRequiredClaimsKeyOption do
      @moduledoc false
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:good_option, 1]

      def token_config, do: %{}
    end

    assert_raise FunctionClauseError,
                 "no function clause matching in Joken.Hooks.RequiredClaims.map_keys/1",
                 fn ->
                   %{claim1: 1, claim2: 2, claim3: 3}
                   |> Config.generate_and_sign!()
                   |> Config.verify_and_validate()
                 end
  end
end
