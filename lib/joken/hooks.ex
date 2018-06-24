defmodule Joken.Hooks do
  @moduledoc """
  Behaviour for defining hooks into Joken's lifecycle.

  Hooks are passed to `Joken` functions or added to `Joken.Config` through the
  `add_hook/2` macro. They can change the execution flow of a token configuration.

  A hook may return:
    - `{:ok, <hook received parameters>}` to let the flow continue.
    - `{:error, reason}` to abort the flow of execution.

  ## `Joken.Config`

  When you create a module that has `use Joken.Config` it automatically implements
  this behaviour with overridable functions. You can simply override a callback 
  implementation directly and it will be triggered when using any of the generated 
  functions. Example:

      defmodule HookToken do
        use Joken.Config
      
        @impl Joken.Hooks
        def before_generate(extra, token_config) do
          IO.puts("Before generating claims")
          {:ok, extra, token_config}
        end
      end

  Now if we call `HookToken.generate_claims/1` it will call our callback.
  """
  alias Joken.Signer

  @type error_tuple :: {:error, term()}

  @type validate_result :: {:ok, Joken.claims()} | error_tuple()

  @doc "Called before `Joken.generate_claims/3`"
  @callback before_generate(extra :: Joken.claims(), Joken.token_config()) ::
              {:ok, extra :: Joken.claims(), Joken.token_config()} | error_tuple()

  @doc "Called before `Joken.encode_and_sign/3`"
  @callback before_sign(Joken.claims(), Signer.t()) ::
              {:ok, Joken.claims(), Signer.t()} | error_tuple()

  @doc "Called before `Joken.verify/3`"
  @callback before_verify(Joken.bearer_token(), Signer.t()) ::
              {:ok, Joken.bearer_token(), Signer.t()} | error_tuple()

  @doc "Called before `Joken.validate/4`"
  @callback before_validate(Joken.claims(), Joken.token_config()) ::
              {:ok, Joken.claims(), Joken.token_config()} | error_tuple()

  @doc "Called after `Joken.generate_claims/3`"
  @callback after_generate(Joken.claims()) :: {:ok, Joken.claims()} | error_tuple()

  @doc "Called after `Joken.encode_and_sign/3`"
  @callback after_sign(Joken.bearer_token(), Joken.claims(), Signer.t()) ::
              {:ok, Joken.bearer_token(), Joken.claims(), Signer.t()} | error_tuple()

  @doc "Called after `Joken.verify/3`"
  @callback after_verify(Joken.bearer_token(), Joken.claims(), Signer.t()) ::
              {:ok, Joken.claims(), Signer.t()} | error_tuple()

  @doc "Called after `Joken.validate/4`"
  @callback after_validate(validate_result(), Joken.claims(), Joken.token_config()) ::
              {:ok, validate_result(), Joken.claims(), Joken.token_config()} | error_tuple()

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Hooks

      @impl true
      def before_generate(extra_claims, claims_config), do: {:ok, extra_claims, claims_config}
      @impl true
      def before_sign(claims, signer), do: {:ok, claims, signer}
      @impl true
      def before_verify(token, signer), do: {:ok, token, signer}
      @impl true
      def before_validate(claims, claims_config), do: {:ok, claims, claims_config}

      @impl true
      def after_generate(claims), do: {:ok, claims}
      @impl true
      def after_sign(token, claims, signer), do: {:ok, token, claims, signer}
      @impl true
      def after_verify(token, claims, signer), do: {:ok, claims, claims, signer}
      @impl true
      def after_validate(validate_result, claims, claims_config),
        do: {:ok, validate_result, claims, claims_config}

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
