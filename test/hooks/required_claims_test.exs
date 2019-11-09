defmodule Joken.Hooks.RequiredClaimsTest do
  use ExUnit.Case, async: true

  test "fails if required claim is missing - list of binaries" do
    defmodule MissingRequiredClaimAsListOfBinaries do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, ["claim1", "claim2"]

      def token_config, do: %{}
    end

    alias MissingRequiredClaimAsListOfBinaries, as: Config

    assert {:error, [message: "Invalid token", missing_claims: ["claim2"]]} ==
             Config.generate_and_sign!(%{claim1: 1, claim3: 3})
             |> Config.verify_and_validate()
  end

  test "succeeds if required claim is present - list of binaries" do
    defmodule RequiredClaimPresentAsListOfBinaries do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, ["claim1", "claim2"]

      def token_config, do: %{}
    end

    alias RequiredClaimPresentAsListOfBinaries, as: Config

    assert {:ok, %{"claim1" => 1, "claim2" => 2, "claim3" => 3}} ==
             Config.generate_and_sign!(%{claim1: 1, claim2: 2, claim3: 3})
             |> Config.verify_and_validate()
  end

  test "fails if required claim is missing - list of atoms" do
    defmodule MissingRequiredClaimAsListOfAtoms do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:claim1, :claim2]

      def token_config, do: %{}
    end

    alias MissingRequiredClaimAsListOfAtoms, as: Config

    assert {:error, [message: "Invalid token", missing_claims: ["claim2"]]} ==
             Config.generate_and_sign!(%{claim1: 1, claim3: 3})
             |> Config.verify_and_validate()
  end

  test "succeeds if required claim is present - list of atoms" do
    defmodule RequiredClaimPresentAsListOfAtoms do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:claim1, :claim2]

      def token_config, do: %{}
    end

    alias RequiredClaimPresentAsListOfAtoms, as: Config

    assert {:ok, %{"claim1" => 1, "claim2" => 2, "claim3" => 3}} ==
             Config.generate_and_sign!(%{claim1: 1, claim2: 2, claim3: 3})
             |> Config.verify_and_validate()
  end

  test "raises if missing options" do
    defmodule MissingRequiredClaimsOptions do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims

      def token_config, do: %{}
    end

    alias MissingRequiredClaimsOptions, as: Config

    assert_raise RuntimeError, "Missing required claims options", fn ->
      Config.generate_and_sign!(%{claim1: 1, claim2: 2, claim3: 3})
      |> Config.verify_and_validate()
    end
  end

  test "raises if options are not a list" do
    defmodule MissingRequiredClaimsOptionsNotAList do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, :my_option

      def token_config, do: %{}
    end

    alias MissingRequiredClaimsOptionsNotAList, as: Config

    assert_raise RuntimeError, "Options must be a list of claim keys", fn ->
      Config.generate_and_sign!(%{claim1: 1, claim2: 2, claim3: 3})
      |> Config.verify_and_validate()
    end
  end

  test "raises if any of the keys is not an atom or string" do
    defmodule BadRequiredClaimsKeyOption do
      use Joken.Config

      add_hook Joken.Hooks.RequiredClaims, [:good_option, 1]

      def token_config, do: %{}
    end

    alias BadRequiredClaimsKeyOption, as: Config

    assert_raise FunctionClauseError,
                 "no function clause matching in Joken.Hooks.RequiredClaims.map_keys/1",
                 fn ->
                   Config.generate_and_sign!(%{claim1: 1, claim2: 2, claim3: 3})
                   |> Config.verify_and_validate()
                 end
  end
end
