defmodule JokenTest do
  use ExUnit.Case

  @secret "test"
  @payload %{ name: "John Doe" }
  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  test "unsupported algorithm" do
    {status, mesg} = Joken.encode(@payload, @secret, :Nope)
    assert(status == :error)
    assert(mesg == "Unsupported algorithm")
  end

  test "encode and decode with HS256" do
    {:ok, token} = Joken.encode(@payload, @secret)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.decode(token, @secret) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS384)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.decode(token, @secret) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS512)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.decode(token, @secret, %{}) 
    assert(@payload == decoded_payload) 
  end

  test "decode token generated with un-sorted keys" do
    {:ok, decoded_payload} = Joken.decode(@unsorted_header_token, @secret, %{})
    assert(@payload == decoded_payload) 
  end

  test "signature validation" do
    {:ok, token} = Joken.encode(@payload, @secret)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")
    {:ok, _} = Joken.decode(token, @secret)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.decode(new_token, @secret)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ exp: Timex.Time.now(:secs) + 300 })
    {status, _} = Joken.decode(token, @secret, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ exp: Timex.Time.now(:secs) - 300 })
    {status, mesg} = Joken.decode(token, @secret, %{})
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf)" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ nbf: Timex.Time.now(:secs) - 300 })
    {status, _} = Joken.decode(token, @secret, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ nbf: Timex.Time.now(:secs) + 300 })
    {status, mesg} = Joken.decode(token, @secret, %{})
    assert(status == :error)
    assert(mesg == "Token not valid yet")  
  end

  test "audience (aud)" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ aud: "self" })
    {status, _} = Joken.decode(token, @secret, %{aud: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ aud: "not:self" })
    {status, mesg} = Joken.decode(token, @secret, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Invalid audience") 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{})
    {status, mesg} = Joken.decode(token, @secret, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "issuer (iss)" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ iss: "self" })
    {status, _} = Joken.decode(token, @secret, %{iss: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ iss: "not:self" })
    {status, mesg} = Joken.decode(token, @secret, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{})
    {status, mesg} = Joken.decode(token, @secret, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "subject (sub)" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ sub: "self" })
    {status, _} = Joken.decode(token, @secret, %{sub: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ sub: "not:self" })
    {status, mesg} = Joken.decode(token, @secret, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Invalid subject") 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{})
    {status, mesg} = Joken.decode(token, @secret, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Missing subject")  
  end

  test "check mulitple claims" do
    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ sub: "test", iss: "self", aud: "self:me" })
    {status, _} = Joken.decode(token, @secret, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ sub: "test", iss: "not:self", aud: "self:me" })
    {status, mesg} = Joken.decode(token, @secret, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(@payload, @secret, :HS256, %{ sub: "test", aud: "self:me" })
    {status, mesg} = Joken.decode(token, @secret, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "malformed token" do
    {status, _} = Joken.decode("foobar", @secret, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
  end
  
end
