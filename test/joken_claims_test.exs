defmodule Joken.Claims.Test do
  use ExUnit.Case, async: true
  import Joken

  defmodule FullDerive do
    @derive Joken.Claims
    defstruct [:a, :b, :c]
  end

  defmodule OnlyDerive do
    @derive {Joken.Claims, only: [:a]}
    defstruct [:a, :b, :c]
  end

  defmodule ExcludeDerive do
    @derive {Joken.Claims, exclude: [:b]}
    defstruct [:a, :b, :c]
  end

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end
  
  test "can derive protocol implementation" do

    token = token
    |> with_claims(%FullDerive{a: 1, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))

    assert token.claims == %{a: 1, b: 2, c: 3}

    compact = token
    |> sign(hs512("test"))
    |> get_compact

    test_struct = compact
    |> token
    |> verify(hs512("test"), as: FullDerive)
    |> get_claims

    assert test_struct == %FullDerive{a: 1, b: 2, c: 3}
  end

  test "can derive protocol with `only` option" do

    token = token
    |> with_claims(%OnlyDerive{a: 1, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))

    assert token.claims == %{a: 1}

    compact = token
    |> sign(hs512("test"))
    |> get_compact

    test_struct = compact
    |> token
    |> verify(hs512("test"), as: OnlyDerive)
    |> get_claims

    assert test_struct == %OnlyDerive{a: 1}
  end

  test "can derive protocol with `exclude` option" do
    
    token = token
    |> with_claims(%ExcludeDerive{a: 1, b: 2, c: 3})
    |> with_validation("a", &(&1 == 1))
    |> with_validation("c", &(&1 == 3))

    assert token.claims == %{a: 1, c: 3}

    compact = token
    |> sign(hs512("test"))
    |> get_compact

    test_struct = compact
    |> token
    |> verify(hs512("test"), as: ExcludeDerive)
    |> get_claims

    assert test_struct == %ExcludeDerive{a: 1, c: 3}
  end

  test "raises on wrong usage of options" do

    assert_raise ArgumentError, "Cannot use both :only and :exclude", fn ->
      defmodule Wrong do
        @derive {Joken.Claims, only: [:a], exclude: [:b]}
        defstruct a: nil, b: nil
      end
    end
  end
end
