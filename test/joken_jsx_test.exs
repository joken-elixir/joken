defmodule Joken.Jsx.Test do
  use ExUnit.Case
  alias Joken.Json

  @secret "test"
  @payload %{ name: "John Doe" }


  defmodule TestJsx do
    alias :jsx, as: JSON
    @behaviour Json

    def encode(map) do
      JSON.encode(map)
    end

    def decode(binary) do
      { _, map } = Enum.map_reduce(JSON.decode(binary), Map.new, fn({key, value}, acc) -> 
        {0, Map.put(acc, String.to_atom(key), value)}
      end)
      map
    end
  end

  @config %{secret_key: @secret, algorithm: :HS256, json_module: TestJsx}

  test "encode and decode with HS256" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    {:ok, joken} = Joken.start_link(@secret, :HS384, TestJsx)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    {:ok, joken} = Joken.start_link(@secret, :HS512, TestJsx)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "signature validation" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")
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
