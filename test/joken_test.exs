defmodule Joken.Test do
  use ExUnit.Case
  
  @payload %{ name: "John Doe" }

  test "signature validation"do
    Application.put_env(:joken, :config_module, Joken.TestPoison)

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
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:exp, _payload) do
        Joken.Config.get_current_time() + 300
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:exp, payload) do
        Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, ExpSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "expiration (exp) failure" do
    defmodule ExpFailureTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:exp, _payload) do
        Joken.Config.get_current_time() - 300
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:exp, payload) do
        Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, ExpFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf) success" do
    defmodule NbfSuccessTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:nbf, _payload) do
        Joken.Config.get_current_time() - 300
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:nbf, payload) do
        Joken.Config.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, NbfSuccessTest)


    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "not before (nbf) failure" do
    defmodule NbfFailureTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end


      def claim(:nbf, _payload) do
        Joken.Config.get_current_time() + 300
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:nbf, payload) do
        Joken.Config.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, NbfFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud) success" do
    defmodule AudSuccessTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:aud, _payload) do
        "Test"
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, AudSuccessTest)


    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "audience (aud) invalid" do
    defmodule InvalidAudienceTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:aud, _payload) do
        "Test"
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:aud, _payload) do
        {:error, "Invalid audience"}
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, InvalidAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid audience")  
  end

  test "audience (aud) missing" do
    defmodule MissingAudienceTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:aud, _payload) do
        "Test"
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:aud, _payload) do
        {:error, "Missing audience"}
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, MissingAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "subject (sub) success" do
    defmodule SubSuccessTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:sub, _payload) do
        "Test"
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, SubSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok)
  end

  test "malformed token" do
    {status, _} = Joken.decode("foobar")
    assert(status == :error)
  end

  test "claim skipping" do
    defmodule ExpSkippedTest do
      alias Poison, as: JSON
      @behaviour Joken.Config

      def secret_key() do
        "test"
      end

      def algorithm() do
        :HS256
      end

      def encode(map) do
        JSON.encode!(map)
      end

      def decode(binary) do
        JSON.decode!(binary, keys: :atoms!)
      end

      def claim(:exp, _payload) do
        Joken.Config.get_current_time() - 100000
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:exp, payload) do
        Joken.Config.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload) do
        :ok
      end
    end 

    Application.put_env(:joken, :config_module, ExpSkippedTest)

    {:ok, expired_token} = Joken.encode(@payload)
    {status, _} = Joken.decode expired_token, skip: [:exp]
    assert(status == :ok)
  end
  
end
