defmodule Joken.ConfigKey.Test do
  use ExUnit.Case
  use Joken, otp_app: :joken, joken_config_key: :my_config
  
  @payload %{ name: "John Doe" }

  test "use different key for joken config" do
    defmodule ExpFailureTest do
      use Joken.Test.BaseConfig

      def claim(:exp, _payload) do
        Joken.Helpers.get_current_time() - 300
      end

      def claim(_, _payload), do: nil

      def validate_claim(:exp, payload, _) do
        Joken.Helpers.validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def validate_claim(_, _payload, _), do: :ok

    end 

    Application.put_env(:joken, :my_config, ExpFailureTest)

    {:ok, token} = encode_token(@payload)
    {status, mesg} = decode_token(token)
    assert(status == :error) 
    assert(mesg == "Token expired") 
  end


end