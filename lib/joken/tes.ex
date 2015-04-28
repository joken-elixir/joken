defmodule Joken.Tes do
  defmacro __using__(_opts) do
    quote do
      def exp(payload) do
        payload
      end

      def nbf(payload) do
        payload
      end

      def aud(payload) do
        payload
      end

      def iss(payload) do
        payload
      end

      def sub(payload) do
        payload
      end

      def iat(payload) do
        payload
      end

      def encode(payload) do
        payload
      end

      def decode(token) do
        token
      end

      defoverridable [encode: 1, decode: 1, iss: 1]
    end
  end
end