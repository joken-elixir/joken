defmodule Joken.Test do
  use ExUnit.Case
  use Joken, otp_app: :joken
  
  @payload %{ name: "John Doe" }

  test "use Joken" do
    {:ok, token} = encode_token(@payload)
    {status, _} = decode_token(token)
    assert(status == :ok) 
  end
  
end
