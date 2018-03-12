defmodule Joken.Hooks do
  @moduledoc """
  Behaviour for defining hooks into Joken's lifecycle. 
  """

  @type claims_config :: %{binary() => Joken.Claim.t()}
  @type claims :: %{binary() => term()}
  @type token :: binary()
  @type validate_result :: {:ok, claims()} | {:error, term()}

  @callback before_generate(extra :: claims(), claims_config()) ::
              {:ok, extra :: claims(), claims_config()}
  @callback before_sign(claims(), Signer.t()) :: {:ok, claims(), Signer.t()}
  @callback before_verify(token(), Signer.t()) :: {:ok, token(), Signer.t()}
  @callback before_validate(claims(), claims_config()) :: {:ok, claims(), claims_config()}

  @callback after_generate(claims()) :: {:ok, claims()}
  @callback after_sign(token(), claims(), Signer.t()) :: {:ok, token()}
  @callback after_verify(token(), claims(), Signer.t()) :: {:ok, claims()}
  @callback after_validate(validate_result(), claims(), claims_config()) ::
              {:ok, validate_result()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Hooks
      def before_generate(extra_claims, claims_config), do: {:ok, extra_claims, claims_config}
      def before_sign(claims, signer), do: {:ok, claims, signer}
      def before_verify(token, signer), do: {:ok, token, signer}
      def before_validate(claims, claims_config), do: {:ok, claims, claims_config}

      def after_generate(claims), do: {:ok, claims}
      def after_sign(token, claims, signer), do: {:ok, token}
      def after_verify(token, claims, signer), do: {:ok, claims}
      def after_validate(validate_result, claims, claims_config), do: {:ok, validate_result}

      defoverridable before_generate: 2,
                     before_sign: 2,
                     before_verify: 2,
                     before_validate: 2,
                     after_generate: 1,
                     after_sign: 3,
                     after_verify: 3,
                     after_validate: 3
    end
  end
end
