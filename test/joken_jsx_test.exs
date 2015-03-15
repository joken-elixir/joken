defmodule Joken.Jsx.Test do
  use ExUnit.Case

  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  @json_module Joken.TestJsx

  @config %{secret_key: @secret, algorithm: :HS256, json_module: @json_module}

  test "encode and decode with HS256" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    {:ok, joken} = Joken.start_link(@secret, :HS384, @json_module)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    {:ok, joken} = Joken.start_link(@secret, :HS512, @json_module)
    {:ok, token} = Joken.encode(joken, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end

  test "decode token generated with un-sorted keys" do
    {:ok, joken} = Joken.start_link(@secret, :HS512, @json_module)
    {:ok, decoded_payload} = Joken.decode(joken, @unsorted_header_token)
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
    {:ok, token} = Joken.encode(joken, @payload, %{ exp: Joken.Utils.get_current_time() + 300 })
    {status, _} = Joken.decode(joken, token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ exp: Joken.Utils.get_current_time() - 300 })
    {status, mesg} = Joken.decode(joken, token, %{})
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ nbf: Joken.Utils.get_current_time() - 300 })
    {status, _} = Joken.decode(joken, token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ nbf: Joken.Utils.get_current_time() + 300 })
    {status, mesg} = Joken.decode(joken, token, %{})
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ aud: "self" })
    {status, _} = Joken.decode(joken, token, %{aud: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ aud: "not:self" })
    {status, mesg} = Joken.decode(joken, token, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Invalid audience") 

    {:ok, token} = Joken.encode(joken, @payload)
    {status, mesg} = Joken.decode(joken, token, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "issuer (iss)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ iss: "self" })
    {status, _} = Joken.decode(joken, token, %{iss: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ iss: "not:self" })
    {status, mesg} = Joken.decode(joken, token, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(joken, @payload)
    {status, mesg} = Joken.decode(joken, token, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "subject (sub)" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ sub: "self" })
    {status, _} = Joken.decode(joken, token, %{sub: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ sub: "not:self" })
    {status, mesg} = Joken.decode(joken, token, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Invalid subject") 

    {:ok, token} = Joken.encode(joken, @payload)
    {status, mesg} = Joken.decode(joken, token, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Missing subject")  
  end

  test "check mulitple claims" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, @payload, %{ sub: "test", iss: "self", aud: "self:me" })
    {status, _} = Joken.decode(joken, token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :ok) 

    {:ok, token} = Joken.encode(joken, @payload, %{ sub: "test", iss: "not:self", aud: "self:me" })
    {status, mesg} = Joken.decode(joken, token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(joken, @payload, %{ sub: "test", aud: "self:me" })
    {status, mesg} = Joken.decode(joken, token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "malformed token" do
    {:ok, joken} = Joken.start_link(@config)
    {status, _} = Joken.decode(joken, "foobar", %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
  end 

  test "using keyword list" do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, token} = Joken.encode(joken, [name: "John Doe"])
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.decode(joken, token) 
    assert(@payload == decoded_payload) 
  end
end
