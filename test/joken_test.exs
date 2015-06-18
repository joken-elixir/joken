defmodule Joken.Test do
  use ExUnit.Case
  
  @payload %{ name: "John Doe" }

  test "signature validation"do
    Application.put_env(:joken, :parameters_module, Joken.TestPoison)

    {:ok, token} = Joken.encode(@payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.decode(token)

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.decode( new_token)
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp) success" do
    defmodule ExpSuccessTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def exp(_payload) do
        Joken.Utils.get_current_time() + 300
      end
    end 

    Application.put_env(:joken, :parameters_module, ExpSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "expiration (exp) failure" do
    defmodule ExpFailureTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def exp(_payload) do
        Joken.Utils.get_current_time() - 300
      end
    end 

    Application.put_env(:joken, :parameters_module, ExpFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf) success" do
    defmodule NbfSuccessTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def nbf(_payload) do
        Joken.Utils.get_current_time() - 300
      end
    end 

    Application.put_env(:joken, :parameters_module, NbfSuccessTest)


    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "not before (nbf) failure" do
    defmodule NbfFailureTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def nbf(_payload) do
        Joken.Utils.get_current_time() + 300
      end
    end 

    Application.put_env(:joken, :parameters_module, NbfFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud) success" do
    defmodule AudSuccessTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def aud(_payload) do
        "Test"
      end
    end 

    Application.put_env(:joken, :parameters_module, AudSuccessTest)


    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "audience (aud) invalid" do
    defmodule InvalidAudienceTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def aud(_payload) do
        "Test"
      end

      def validate_aud(_payload) do
        {:error, "Invalid audience"}
      end
    end 

    Application.put_env(:joken, :parameters_module, InvalidAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid audience")  
  end

  test "audience (aud) missing" do
    defmodule MissingAudienceTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def validate_aud(_payload) do
        {:error, "Missing audience"}
      end
    end 

    Application.put_env(:joken, :parameters_module, MissingAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "issuer (iss) success" do
    defmodule IssSuccessTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def iss(_payload) do
        "Test"
      end
    end 

    Application.put_env(:joken, :parameters_module, IssSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "issuer (iss) invalid" do
    defmodule IssInvalidTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def iss(_payload) do
        "Test"
      end

      def validate_iss(_payload) do
        {:error, "Invalid issuer"}
      end
    end 

    Application.put_env(:joken, :parameters_module, IssInvalidTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid issuer")
  end

  test "issuer (iss) missing" do
    defmodule IssMissingTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def iss(_payload) do
        "Test"
      end

      def validate_iss(_payload) do
        {:error, "Missing issuer"}
      end
    end 

    Application.put_env(:joken, :parameters_module, IssMissingTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing issuer")  
  end

  test "subject (sub) success" do
    defmodule SubSuccessTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def sub(_payload) do
        "Test"
      end
    end 

    Application.put_env(:joken, :parameters_module, SubSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok)
  end

  test "subject (sub) invalid" do
    defmodule SubInvalidTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def sub(_payload) do
        "Test"
      end

      def validate_sub(_payload) do
        {:error, "Invalid subject"}
      end
    end 

    Application.put_env(:joken, :parameters_module, SubInvalidTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid subject")

  end

  test "subject (sub) missing" do

    defmodule SubMissingTest do
      alias Poison, as: JSON
      use Joken.Parameters

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def sub(_payload) do
        "Test"
      end

      def validate_sub(_payload) do
        {:error, "Missing subject"}
      end
    end 

    Application.put_env(:joken, :parameters_module, SubMissingTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing subject")  
  end

  test "malformed token" do
    {status, _} = Joken.decode("foobar")
    assert(status == :error)
  end

  test "claim skipping" do
    expiration = Joken.Utils.get_current_time() - 100000
    {:ok, expired_token} = Joken.encode(Map.put(@payload, :exp, expiration))
    {status, _} = Joken.decode expired_token, skip: [:exp]
    assert(status == :ok)
  end
  
end
