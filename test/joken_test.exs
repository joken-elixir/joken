defmodule Joken.Test do
  use ExUnit.Case

  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  @json_module Joken.TestPoison

  test "creation of Joken passing config name" do
    {status, joken} = Joken.start_link(:my_otp_app)
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS256
  end

  test "creation of Joken passing config" do
    {status, joken} = Joken.start_link(%{secret_key: @secret, algorithm: :HS256, json_module: @json_module})
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS256
  end

  test "creation of Joken passing all parameters" do
    {status, joken} = Joken.start_link(@secret, :HS384, @json_module)
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS384
  end
  
end
