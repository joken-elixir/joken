defmodule Joken.ClaimTest do
  use ExUnit.Case, async: true

  alias Joken.Claim

  test "can generate values" do
    claim = %Claim{generate: fn -> "New Value" end}
    assert Claim.__generate_claim__({"val", claim}, %{}) == %{"val" => "New Value"}
  end

  test "when generate function is nil skips generation" do
    claim = %Claim{generate: nil}
    assert Claim.__generate_claim__({"val", claim}, %{}) == %{}
  end

  test "when generate function has arity different than 0 skips generation" do
    claim = %Claim{generate: fn _wth -> "nope wont do" end}
    assert Claim.__generate_claim__({"val", claim}, %{}) == %{}
  end
end
