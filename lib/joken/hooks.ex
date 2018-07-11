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

  @type error_tuple :: {:error, term}

  @type halt_tuple :: {:halt, term}

  @type validate_result :: {:ok, Joken.claims()} | error_tuple

  @type hook_options :: Keyword.t()

  @type status :: :ok | error_tuple

  @doc "Called before `Joken.generate_claims/3`"
  @callback before_generate(hook_options, extra :: Joken.claims(), Joken.token_config()) ::
              {status, extra :: Joken.claims(), Joken.token_config()} | halt_tuple

  @doc "Called before `Joken.encode_and_sign/3`"
  @callback before_sign(hook_options, Joken.claims(), Signer.t()) ::
              {status, Joken.claims(), Signer.t()} | halt_tuple

  @doc "Called before `Joken.verify/3`"
  @callback before_verify(hook_options, Joken.bearer_token(), Signer.t()) ::
              {status, Joken.bearer_token(), Signer.t()} | halt_tuple

  @doc "Called before `Joken.validate/4`"
  @callback before_validate(hook_options, Joken.claims(), Joken.token_config()) ::
              {status, Joken.claims(), Joken.token_config()} | halt_tuple

  @doc "Called after `Joken.generate_claims/3`"
  @callback after_generate(hook_options, Joken.claims()) :: {status, Joken.claims()} | halt_tuple

  @doc "Called after `Joken.encode_and_sign/3`"
  @callback after_sign(
              hook_options,
              status,
              Joken.bearer_token(),
              Joken.claims(),
              Signer.t()
            ) :: {status, Joken.bearer_token(), Joken.claims(), Signer.t()} | halt_tuple

  @doc "Called after `Joken.verify/3`"
  @callback after_verify(
              hook_options,
              status,
              Joken.bearer_token(),
              Joken.claims(),
              Signer.t()
            ) :: {status, Joken.claims(), Signer.t()} | halt_tuple

  @doc "Called after `Joken.validate/4`"
  @callback after_validate(
              hook_options,
              status,
              Joken.claims(),
              Joken.token_config()
            ) :: {status, Joken.claims(), Joken.token_config()} | halt_tuple

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Hooks

      @impl true
      def before_generate(_hook_options, extra_claims, claims_config),
        do: {:ok, extra_claims, claims_config}

      @impl true
      def before_sign(_hook_options, claims, signer), do: {:ok, claims, signer}
      @impl true
      def before_verify(_hook_options, token, signer), do: {:ok, token, signer}
      @impl true
      def before_validate(_hook_options, claims, claims_config),
        do: {:ok, claims, claims_config}

      @impl true
      def after_generate(_hook_options, claims), do: {:ok, claims}

      @impl true
      def after_sign(_hook_options, status, token, claims, signer),
        do: {status, token, claims, signer}

      @impl true
      def after_verify(_hook_options, status, token, claims, signer),
        do: {status, claims, claims, signer}

      @impl true
      def after_validate(_hook_options, status, claims, claims_config),
        do: {status, claims, claims_config}

      defoverridable before_generate: 3,
                     before_sign: 3,
                     before_verify: 3,
                     before_validate: 3,
                     after_generate: 2,
                     after_sign: 5,
                     after_verify: 5,
                     after_validate: 4
    end
  end
end
