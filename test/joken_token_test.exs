defmodule Joken.Token.Test do
  use ExUnit.Case

  @moduledoc """
  Tests calling the Joken.Token module directly
  """
  @secret "test"
  @payload %{ name: "John Doe" }

  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim {"name": "John Doe"}, secret "test"
  @unsorted_header_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I"

  @unsorted_payload %{
    iss: "https://example.com/",
    sub: "example|123456",
    aud: "abc123",
    iat: 1428371188
  }
  # generated at jwt.io with header {"typ": "JWT", "alg": "HS256"}, claim @unsorted_payload, secret "test"
  @unsorted_payload_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tLyIsInN1YiI6ImV4YW1wbGV8MTIzNDU2IiwiYXVkIjoiYWJjMTIzIiwiaWF0IjoxNDI4MzcxMTg4fQ.w9Elb3Ogomd1hm0bAvjbrOPIDhZhgOxckG_ztDJVhJs"

  @poison_json_module Joken.TestPoison
  @jsx_json_module Joken.TestJsx

  # base config that is overriden in each test
  defmodule BaseConfig do

    @moduledoc false

    defmacro __using__(_opts) do
      quote do
        @behaviour Joken.Config

        def secret_key(), do: "test"
        def algorithm(), do: :HS256
        def encode(map), do: Poison.encode!(map)
        def decode(binary), do: Poison.decode!(binary, keys: :atoms!)
        def claim(_claim, _payload), do: nil
        def validate_claim(_claim, _payload, _options), do: :ok

        defoverridable [algorithm: 0, encode: 1, decode: 1, claim: 2, validate_claim: 3]
      end
    end
  end
  
  test "encode and decode with HS256 (Poison)" do
    {:ok, token} = Joken.Token.encode(@poison_json_module, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")

    {:ok, decoded_payload} = Joken.Token.decode(@poison_json_module, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384 (Poison)" do

    defmodule Decode384 do
      use BaseConfig

      def algorithm(), do: :HS384
    end

    {:ok, token} = Joken.Token.encode(Decode384, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zDrtMUaPYXpFdESkmnjzMgDZsHC6LObDfrEdryAzZ981r77Td2BZ61rx09tsJFvP")

    {:ok, decoded_payload} = Joken.Token.decode(Decode384, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512 (Poison)" do

    defmodule Decode512 do
      use BaseConfig

      def algorithm(), do: :HS512
    end

    {:ok, token} = Joken.Token.encode(Decode512, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.olXW3I_OpLs9bfthg49kVIgUFHTjLCoCEGthWICMd2DZyGyIn0eAcjF3KuMA29Yb6W9kyAYf1dKn7sPwEajcmA")

    {:ok, decoded_payload} = Joken.Token.decode(Decode512, token) 
    assert(@payload == decoded_payload) 
  end

  test "decode token generated with un-sorted keys (Poison)" do
    {:ok, _} = Joken.Token.encode(@poison_json_module, @payload)
    {:ok, decoded_payload} = Joken.Token.decode(@poison_json_module, @unsorted_header_token) 
    assert(@payload == decoded_payload) 
  end

  test "signature validation (Poison)" do
    {:ok, token} = Joken.Token.encode(@poison_json_module, @payload)
    assert(token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.B3tqUk6UdT8K5AQUGdYFXPj7R7_JznRi5PRrv_N7d1I")
    {:ok, _} = Joken.Token.decode(@poison_json_module, token) 

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.Token.decode(@poison_json_module, new_token) 
    assert(mesg == "Invalid signature") 
  end

  test "signature validation unsorted payload (Poison)" do
    assert {:ok, _} = Joken.Token.decode(@poison_json_module, @unsorted_payload_token)
  end

  test "error with invalid algorithm" do

    defmodule Decode1024 do
      use BaseConfig

      def algorithm(), do: :HS1024
    end

    {:error, message} = Joken.Token.encode(Decode1024, @payload)
    assert message == "Unsupported algorithm"
  end
  
  test "encode and decode with HS256 (JSX)" do
    {:ok, token} = Joken.Token.encode(@jsx_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")

    {:ok, decoded_payload} = Joken.Token.decode(@jsx_json_module, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS384 (JSX)" do
    defmodule TestJsx384 do
      use BaseConfig

      def algorithm(), do: :HS384

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsx384, @payload)
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.YOH6U5Ggk5_o5B7Dg3pacaKcPkrbFEX-30-trLV6C6wjTHJ_975PXLSEzebOSP8k")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsx384, token) 
    assert(@payload == decoded_payload) 
  end

  test "encode and decode with HS512 (JSX)" do

    defmodule TestJsx512 do
      use BaseConfig

      def algorithm(), do: :HS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsx512, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:ok, decoded_payload} = Joken.Token.decode(TestJsx512, token) 
    assert(@payload == decoded_payload) 
  end

  test "missing signature" do

    defmodule TestJsx512Missing do
      use BaseConfig

      def algorithm(), do: :HS512

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {:ok, token} = Joken.Token.encode(TestJsx512Missing, @payload)
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.zi1zohSNwRdHftnWKE16vE3VmbGFtG27LxbYDXAodVlX7T3ATgmJJPjluwf2SPKJND2-O7alOq8NWv6EAnWWyg")

    {:error, message} = Joken.Token.decode(TestJsx512Missing, "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ") 
    assert("Missing signature" == message) 
  end

  test "unsecure token" do
    defmodule TestJsxNone do
      use BaseConfig

      def algorithm(), do: :none

      def encode(map), do: :jsx.encode(map)

      def decode(binary) do
        :jsx.decode(binary)
        |> Enum.map(fn({key, value})-> {String.to_atom(key), value} end)
      end
    end

    {status, message} = Joken.Token.decode(TestJsxNone, "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ")
    assert(status == :error)
    assert(message == "Missing signature")
  end

  test "decode token generated with un-sorted keys (JSX)" do
    {:ok, _} = Joken.Token.encode(@jsx_json_module, @payload)
    {:ok, decoded_payload} = Joken.Token.decode(@jsx_json_module, @unsorted_header_token) 
    assert(@payload == decoded_payload) 
  end

  test "signature validation (JSX)" do
    {:ok, token} = Joken.Token.encode(@jsx_json_module, @payload)
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OQ")
    {:ok, _} = Joken.Token.decode(@jsx_json_module, token) 

    new_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UifQ.3fazvmF342WiHp5uhY-wkWArn-YJxq1IO7Msrtfk-OD"
    {:error, mesg} = Joken.Token.decode(@jsx_json_module, new_token) 
    assert(mesg == "Invalid signature") 
  end

  test "expiration (exp)" do
    defmodule ExpSuccessTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "exp", "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _, _), do: :ok
    end

    defmodule ExpFailureTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "exp", "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _, _), do: :ok
    end 

    {:ok, token} = Joken.Token.encode(ExpSuccessTest,  %{ "name" => "John Doe" })
    {status, _} = Joken.Token.decode(ExpSuccessTest, token)
    assert(status == :ok)

    {:ok, token} = Joken.Token.encode(ExpFailureTest, %{ "name" => "John Doe" })
    {status, mesg} = Joken.Token.decode(ExpFailureTest, token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end

  test "valid iat claim" do

    defmodule IatSuccessTest do
      use BaseConfig

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:iat, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _), do: nil

      def validate_claim(:iat, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "iat", "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def validate_claim(_, _, _), do: :ok
    end

    defmodule IatFailureTest do
      use BaseConfig
      require Logger

      def decode(binary), do: Poison.decode!(binary)
      
      def claim(:iat, _payload) do
        Joken.Helpers.get_current_time() + 300
      end

      def claim(_, _), do: nil

      def validate_claim(:iat, payload, _) do
        Joken.Helpers.validate_time_claim(payload, "iat", "Token not valid yet", &(&1 < &2))
      end

      def validate_claim(_, _, _), do: :ok
    end 

    {:ok, token} = Joken.Token.encode(IatSuccessTest,  %{ "name" => "John Doe" })
    assert {:ok, _} = Joken.Token.decode(IatSuccessTest, token)

    {:ok, token} = Joken.Token.encode(IatFailureTest,  %{ "name" => "John Doe" })
    assert {:error, "Token not valid yet"} == Joken.Token.decode(IatFailureTest, token)
  end
end
