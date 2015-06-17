defmodule Joken.Parameters do
  use Behaviour

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Parameters

      def exp(payload) do
        nil
      end

      def validate_exp(payload) do
        validate_time_claim(payload, :exp, "Token expired", fn(expires_at, now) -> expires_at > now end)
      end

      def nbf(payload) do
        nil
      end

      def validate_nbf(payload) do
        validate_time_claim(payload, :nbf, "Token not valid yet", fn(not_before, now) -> not_before < now end) 
      end

      def iat(payload) do
        nil
      end

      def validate_iat(payload) do
        validate_time_claim(payload, :iat, "Token not valid yet", fn(not_before, now) -> not_before < now end)
      end

      def aud(payload) do
        nil
      end

      def validate_aud(payload) do
        {:ok, payload}  
      end

      def iss(payload) do
        nil
      end

      def validate_iss(payload) do
        {:ok, payload}  
      end

      def sub(payload) do
        nil
      end

      def validate_sub(payload) do
        {:ok, payload}  
      end

      def jti(payload) do
        nil
      end

      def validate_jti(payload) do
        {:ok, payload}
      end

      def validate_time_claim(payload, key, error_msg, validate_time_fun) do
        key_found? = case payload do
          p when is_map(p) ->
            Map.has_key?(payload, key)
          _ ->
            Keyword.has_key?(payload, key)
        end

        current_time = Joken.Utils.get_current_time()

        cond do
          key_found? and validate_time_fun.(payload[key], current_time) ->
            {:ok, payload}
          key_found? and !validate_time_fun.(payload[key], current_time) ->
            {:error, error_msg}
          true ->
            {:ok, payload}        
        end
      end

      def validate_claim(payload, key_to_check, value, full_name) do
        key_found? = case payload do
          p when is_map(p) ->
            Map.has_key?(payload, key_to_check)
          _ ->
            Keyword.has_key?(payload, key_to_check)
        end

        cond do
          value == nil ->
            {:ok, payload}        
          key_found? and payload[key_to_check] == value ->
            {:ok, payload}
          key_found? and payload[key_to_check] != value ->
            {:error, "Invalid #{full_name}"}
          !key_found? ->
            {:error, "Missing #{full_name}"}
          true ->
            {:ok, payload}        
        end
      end

      defoverridable [
        exp: 1, validate_exp: 1,
        nbf: 1, validate_nbf: 1,
        aud: 1, validate_aud: 1,
        iss: 1, validate_iss: 1,
        sub: 1, validate_sub: 1,
        iat: 1, validate_iat: 1,
        jti: 1, validate_jti: 1,
      ]
    end
  end

  @doc """
  encode can take either a map or a keyword list or both and return a string.   
  """
  defcallback encode(Joken.payload) :: String.t
  
  @doc """
  decode can take a string and return a map or a keyword list. 
  """
  defcallback decode(String.t) :: Joken.payload
end