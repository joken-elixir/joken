defmodule Joken.Poison.Test do
  use ExUnit.Case
  alias Joken.Json

  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"


  defmodule TestPoison do
    alias Poison, as: JSON
    @behaviour Json

    def encode(map) do
      JSON.encode!(map)
    end

    def decode(binary) do
      JSON.decode!(binary, keys: :atoms!)
    end
  end

  @config %{secret_key: @secret, algorithm: :HS256, json_module: TestPoison}

  test "creation of Joken passing config name" do
    {status, joken} = Joken.start_link(:my_otp_app)
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS256
  end

  test "creation of Joken passing config" do
    {status, joken} = Joken.start_link(@config)
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS256
  end


  test "creation of Joken passing all parameters" do
    {status, joken} = Joken.start_link(@secret, :HS384, TestPoison)
    assert status == :ok
    assert Joken.config(joken).algorithm == :HS384
  end

  test "encode and decode with HS256" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    {:ok, joken} = Joken.start_link(@secret, :HS384, TestPoison)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zDrtMUaPYXpFdESkmnjzMgDZsHC6LObDfrEdryAzZ981r77Td2BZ61rx09tsJFvP")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    {:ok, joken} = Joken.start_link(@secret, :HS512, TestPoison)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.olXW3I_OpLs9bfthg49kVIgUFHTjLCoCEGthWICMd2DZyGyIn0eAcjF3KuMA29Yb6W9kyAYf1dKn7sPwEajcmA")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "decode token generated with un-sorted keys" do
    {:ok, joken} = Joken.start_link(@secret, :HS512, TestPoison)
    {:ok, decoded_payload} = Joken.decode(joken, @unsorted_header_token)
    assert(@payload == decoded_payload) 
  end

  test "signature validation" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.decode(joken, token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.decode(joken, new_token)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ exp: Timex.Time.now(:secs) + 300 })
    {status, _} = Joken.decode(joken, token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ exp: Timex.Time.now(:secs) - 300 })
    {status, mesg} = Joken.decode(joken, token, %{})
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ nbf: Timex.Time.now(:secs) - 300 })
    {status, _} = Joken.decode(joken, token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ nbf: Timex.Time.now(:secs) + 300 })
    {status, mesg} = Joken.decode(joken, token, %{})
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end
  
end
