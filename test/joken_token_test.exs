defmodule Joken.Token.Test do
  use ExUnit.Case

  @moduledoc """
  Tests calling the Joken.Token module directly
  """

  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  @json_module Joken.TestPoison

  test "encode and decode with HS256" do
    {:ok, token} = Joken.Token.encode(@secret, :HS256, @json_module, @payload, %{})
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")

    {:ok, decoded_payload} = Joken.Token.decode(@secret, @json_module, token, %{}) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    {:ok, token} = Joken.Token.encode(@secret, :HS384, @json_module, @payload, %{})
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zDrtMUaPYXpFdESkmnjzMgDZsHC6LObDfrEdryAzZ981r77Td2BZ61rx09tsJFvP")

    {:ok, decoded_payload} = Joken.Token.decode(@secret, @json_module, token, %{}) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    {:ok, token} = Joken.Token.encode(@secret, :HS512, @json_module, @payload, %{})
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.olXW3I_OpLs9bfthg49kVIgUFHTjLCoCEGthWICMd2DZyGyIn0eAcjF3KuMA29Yb6W9kyAYf1dKn7sPwEajcmA")

    {:ok, decoded_payload} = Joken.Token.decode(@secret, @json_module, token, %{}) 
    assert(@payload == decoded_payload) 
  end

  test "decode token generated with un-sorted keys" do
    {:ok, token} = Joken.Token.encode(@secret, :HS512, @json_module, @payload, %{})
    {:ok, decoded_payload} = Joken.Token.decode(@secret, @json_module, @unsorted_header_token, %{}) 
    assert(@payload == decoded_payload) 
  end

  test "signature validation" do
    {:ok, token} = Joken.Token.encode(@secret, :HS256, @json_module, @payload, %{})
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.Token.decode(@secret, @json_module, token, %{}) 

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.Token.decode(@secret, @json_module, new_token, %{}) 
    assert(mesg == "Invalid signature") 
  end
  
end
