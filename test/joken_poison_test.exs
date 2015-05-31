defmodule Joken.Poison.Test do
  use ExUnit.Case
  
  @payload %{ name: "John Doe" }

  @json_module Joken.TestPoison

  test "signature validation"do
    {:ok, token} = Joken.encode(@payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.decode(token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.decode( new_token)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)" do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf)"do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud)"do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid audience") 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "issuer (iss)"do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "subject (sub)"do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid subject") 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing subject")  
  end

  test "check mulitple claims"do
    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid issuer") 

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "malformed token"do
    {status, _} = Joken.decode("foobar")
    assert(status == :error)
  end 
  
end
