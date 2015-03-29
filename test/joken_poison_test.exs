defmodule Joken.Poison.Test do
  use ExUnit.Case
  
  @payload %{ name: "John Doe" }

  @json_module Joken.TestPoison

  @config %{secret_key: "test", algorithm: :HS256, json_module: @json_module}

  setup_all do
    {:ok, joken} = Joken.start_link(@config)
    {:ok, joken: joken}
  end

  test "signature validation", context do
    {:ok, token} = Joken.encode(context[:joken], @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.decode(context[:joken], token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.decode(context[:joken], new_token)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ exp: Joken.Utils.get_current_time() + 300 })
    {status, _} = Joken.decode(context[:joken], token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ exp: Joken.Utils.get_current_time() - 300 })
    {status, mesg} = Joken.decode(context[:joken], token, %{})
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf)", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ nbf: Joken.Utils.get_current_time() - 300 })
    {status, _} = Joken.decode(context[:joken], token, %{})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ nbf: Joken.Utils.get_current_time() + 300 })
    {status, mesg} = Joken.decode(context[:joken], token, %{})
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud)", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ aud: "self" })
    {status, _} = Joken.decode(context[:joken], token, %{aud: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ aud: "not:self" })
    {status, mesg} = Joken.decode(context[:joken], token, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Invalid audience") 

    {:ok, token} = Joken.encode(context[:joken], @payload)
    {status, mesg} = Joken.decode(context[:joken], token, %{ aud: "self" })
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "issuer (iss)", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ iss: "self" })
    {status, _} = Joken.decode(context[:joken], token, %{iss: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ iss: "not:self" })
    {status, mesg} = Joken.decode(context[:joken], token, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(context[:joken], @payload)
    {status, mesg} = Joken.decode(context[:joken], token, %{ iss: "self" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "subject (sub)", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ sub: "self" })
    {status, _} = Joken.decode(context[:joken], token, %{sub: "self"})
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ sub: "not:self" })
    {status, mesg} = Joken.decode(context[:joken], token, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Invalid subject") 

    {:ok, token} = Joken.encode(context[:joken], @payload)
    {status, mesg} = Joken.decode(context[:joken], token, %{ sub: "self" })
    assert(status == :error)
    assert(mesg == "Missing subject")  
  end

  test "check mulitple claims", context do
    {:ok, token} = Joken.encode(context[:joken], @payload, %{ sub: "test", iss: "self", aud: "self:me" })
    {status, _} = Joken.decode(context[:joken], token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :ok) 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ sub: "test", iss: "not:self", aud: "self:me" })
    {status, mesg} = Joken.decode(context[:joken], token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(context[:joken], @payload, %{ sub: "test", aud: "self:me" })
    {status, mesg} = Joken.decode(context[:joken], token, %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "malformed token", context do
    {status, _} = Joken.decode(context[:joken], "foobar", %{ sub: "test", iss: "self", aud: "self:me" })
    assert(status == :error)
  end 
  
end
