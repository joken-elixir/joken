defmodule Joken.Test do
  use ExUnit.Case
  
  @payload %{ name: "John Doe" }

  defmodule BaseConfig do

    defmacro __using__(_opts) do
      quote do
        @behaviour Joken.Config

        def secret_key(), do: "test"
        def algorithm(), do: :HS256
        def encode(map), do: Poison.encode!(map)
        def decode(binary), do: Poison.decode!(binary, keys: :atoms!)
        def claim(_claim, _payload), do: nil
        def validate_claim(_claim, _payload, _options), do: :ok

        defoverridable algorithm: 0, encode: 1, decode: 1, claim: 2, validate_claim: 3
      end
    end
    
  end
  
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
      use BaseConfig

      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _payload) do
        nil
      end

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload, _) do
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
      use BaseConfig

      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _payload), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload, _), do: :ok

    end 

    Application.put_env(:joken, :config_module, ExpFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "not before (nbf) success" do
    defmodule NbfSuccessTest do
      use BaseConfig

      def claim(:nbf, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _payload), do: nil

      def validate_claim(:nbf, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, NbfSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "not before (nbf) failure" do

    defmodule NbfFailureTest do
      use BaseConfig

      def claim(:nbf, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _payload), do: nil

      def validate_claim(:nbf, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, NbfFailureTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error) 
    assert(mesg == "Token not valid yet") 
  end

  test "audience (aud) success" do
    defmodule AudSuccessTest do
      use BaseConfig

      def claim(:aud, _payload), do: "Test"
      def claim(_, _payload), do: nil
      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, AudSuccessTest)

    {:ok, token} = Joken.encode(@payload)
    {status, _} = Joken.decode(token)
    assert(status == :ok) 
  end

  test "audience (aud) invalid" do
    defmodule InvalidAudienceTest do
      use BaseConfig

      def claim(:aud, _payload), do: "Test"
      def claim(_, _payload), do: nil

      def validate_claim(:aud, _payload, _) do
        {:error, "Invalid audience"}
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, InvalidAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Invalid audience")  
  end

  test "audience (aud) missing" do
    defmodule MissingAudienceTest do
      use BaseConfig
      
      def claim(:aud, _payload), do: "Test"
      def claim(_, _payload), do: nil

      def validate_claim(:aud, _payload, _) do
        {:error, "Missing audience"}
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, MissingAudienceTest)

    {:ok, token} = Joken.encode(@payload)
    {status, mesg} = Joken.decode(token)
    assert(status == :error)
    assert(mesg == "Missing audience")  
  end

  test "subject (sub) success" do
    defmodule SubSuccessTest do
      use BaseConfig

      def claim(:sub, _payload), do: "Test"
      def claim(_, _payload), do: nil

      def validate_claim(_, _payload, _), do: :ok
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
      use BaseConfig

      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() - 100000
      end

      def claim(_, _payload), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, ExpSkippedTest)

    {:ok, expired_token} = Joken.encode(@payload)
    {status, _} = Joken.decode expired_token, skip: [:exp]
    assert(status == :ok)
  end

  test "passing in extra data" do
    defmodule ExtraDataTest do
      use BaseConfig

      def claim(:aud, _payload), do: "update"
      def claim(_, _payload), do: nil

      def validate_claim(:aud, payload, options) do
        if Dict.get(options, :aud) == Dict.get(payload, :aud) do
          :ok
        else
          {:error, "Invalid AUD"}
        end
        
      end

      def validate_claim(_, _payload, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, ExtraDataTest)
    {:ok, token} = Joken.encode(%{aud: "update"})
    {status, _} = Joken.decode token, [aud: "update"]
    assert(status == :ok)

  end

  test "validate custom claim from options" do
    defmodule CustomClaimTest do
      use BaseConfig

      def claim(_, _), do: nil

      def validate_claim(:user_id, payload, options) do
        if Dict.get(options, :user_id) == Dict.get(payload, :user_id) do
          :ok
        else
          {:error, "Invalid User Id"}
        end
        
      end

      def validate_claim(_, _, _), do: :ok
    end 

    Application.put_env(:joken, :config_module, CustomClaimTest)
    {:ok, token} = Joken.encode(%{user_id: "abc"})
    {status, _} = Joken.decode token, [user_id: "abc"]
    assert(status == :ok)

    {status, _} = Joken.decode token, [user_id: "cba"]
    assert(status == :error)
  end

  defmodule StructToken do
    use BaseConfig

    defstruct nbf: nil

    def decode(binary), do: Poison.decode!(binary, keys: :atoms!, as: Joken.Test.StructToken)    
    
    def validate_claim(:nbf, payload, _) do
      Joken.Helpers.validate_time_claim(payload, :nbf, "Token not valid yet",
        fn(not_before, now) ->
           not_before < now
        end) 
    end

    def validate_claim(_, _payload, _), do: :ok
  end
  
  test "struct not before (nbf) success" do

    Application.put_env(:joken, :config_module, StructToken)
    struct = %StructToken{nbf: Joken.Helpers.get_current_time() - 300}

    {:ok, token} = Joken.encode(struct)
    {status, _} = Joken.decode(token)
    assert status == :ok
  end

  test "struct not before (nbf) failure" do

    Application.put_env(:joken, :config_module, StructToken)
    struct = %StructToken{nbf: Joken.Helpers.get_current_time() + 300}

    {:ok, token} = Joken.encode(struct)
    {status, message} = Joken.decode(token)
    assert status == :error
    assert message == "Token not valid yet"
  end
  
end
