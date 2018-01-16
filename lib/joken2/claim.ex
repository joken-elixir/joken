defmodule Joken2.Claim do
  defstruct generate: nil, validate: nil

  def generate_claim({key, %Joken2.Claim{generate: gen_fun}}, acc) do
    Map.put(acc, key, gen_fun.())
  end
end