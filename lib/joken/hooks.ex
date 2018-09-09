defmodule Joken.Hooks do
  @moduledoc """
  Behaviour for defining hooks into Joken's lifecycle.

  Hooks are passed to `Joken` functions or added to `Joken.Config` through the
  `add_hook/2` macro. They can change the execution flow of a token configuration.

  Hooks are executed in a reduce_while call and so must always return either:
    - `{:halt, result}` -> when you want to abort execution
    - `{:cont, result}` -> when you want to let other hooks execute

  When you want to let execution proceed, result must be a tuple where:
    - the first element is the status: `:ok` | `{:error, reason}`
    - other arguments are what is expected as the arguments for the next hook in 
      the chain

  For example:

      defmodule MyHaltHook do
        use Joken.Hooks
      
        @impl true
        def before_generate(_hook_options, _extra_claims, _token_config) do
          {:halt, {:error, :no_go}}
        end
      end

  In this case `MyHaltHook` will abort execution returning `{:error, :no_go}`.

  Another example:

      defmodule CheckVerifyError do
        use Joken.Hooks
        require Logger

        @impl true
        def after_verify(hook_options, status, bearer_token, claims_map, signer) do
          case status do
            {:error, :invalid_signature} = err ->
              Logger.error("Check signer!!!")
              {:halt, err}
          
            :ok ->
              {:cont, {:ok, bearer_token, claims_map, signer}}
          end
        end
      end

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

  Also, in `Joken.Config` a macro is imported for adding hooks with options. Example:

      defmodule ManyHooks do
        use Joken.Config

        add_hook(JokenJwks, jwks_url: "http://someserver.com/.well-known/certs")
      end
  """
  alias Joken.Signer

  @type error_tuple :: {:error, term}

  @type halt_tuple :: {:halt, term}

  @type validate_result :: {:ok, Joken.claims()} | error_tuple

  @type hook_options :: Keyword.t()

  @type status :: :ok | error_tuple

  @doc "Called before `Joken.generate_claims/3`"
  @callback before_generate(hook_options, status, extra :: Joken.claims(), Joken.token_config()) ::
              {:cont, {status, extra :: Joken.claims(), Joken.token_config()}} | halt_tuple

  @doc "Called before `Joken.encode_and_sign/3`"
  @callback before_sign(hook_options, status, Joken.claims(), Signer.t()) ::
              {:cont, {status, Joken.claims(), Signer.t()}} | halt_tuple

  @doc "Called before `Joken.verify/3`"
  @callback before_verify(hook_options, status, Joken.bearer_token(), Signer.t()) ::
              {:cont, {status, Joken.bearer_token(), Signer.t()}} | halt_tuple

  @doc "Called before `Joken.validate/4`"
  @callback before_validate(hook_options, status, Joken.claims(), Joken.token_config()) ::
              {:cont, {status, Joken.claims(), Joken.token_config()}} | halt_tuple

  @doc "Called after `Joken.generate_claims/3`"
  @callback after_generate(hook_options, status, Joken.claims()) ::
              {:cont, {status, Joken.claims()}} | halt_tuple

  @doc "Called after `Joken.encode_and_sign/3`"
  @callback after_sign(
              hook_options,
              status,
              Joken.bearer_token(),
              Joken.claims(),
              Signer.t()
            ) :: {:cont, {status, Joken.bearer_token(), Joken.claims(), Signer.t()}} | halt_tuple

  @doc "Called after `Joken.verify/3`"
  @callback after_verify(
              hook_options,
              status,
              Joken.bearer_token(),
              Joken.claims(),
              Signer.t()
            ) :: {:cont, {status, Joken.claims(), Signer.t()}} | halt_tuple

  @doc "Called after `Joken.validate/4`"
  @callback after_validate(
              hook_options,
              status,
              Joken.claims(),
              Joken.token_config()
            ) :: {:cont, {status, Joken.claims(), Joken.token_config()}} | halt_tuple

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Hooks

      @impl true
      def before_generate(_hook_options, status, extra_claims, claims_config),
        do: {:cont, {status, extra_claims, claims_config}}

      @impl true
      def before_sign(_hook_options, status, claims, signer),
        do: {:cont, {status, claims, signer}}

      @impl true
      def before_verify(_hook_options, status, token, signer),
        do: {:cont, {status, token, signer}}

      @impl true
      def before_validate(_hook_options, status, claims, claims_config),
        do: {:cont, {status, claims, claims_config}}

      @impl true
      def after_generate(_hook_options, status, claims),
        do: {:cont, {status, claims}}

      @impl true
      def after_sign(_hook_options, status, token, claims, signer),
        do: {:cont, {status, token, claims, signer}}

      @impl true
      def after_verify(_hook_options, status, token, claims, signer),
        do: {:cont, {status, claims, claims, signer}}

      @impl true
      def after_validate(_hook_options, status, claims, claims_config),
        do: {:cont, {status, claims, claims_config}}

      defoverridable before_generate: 4,
                     before_sign: 4,
                     before_verify: 4,
                     before_validate: 4,
                     after_generate: 3,
                     after_sign: 5,
                     after_verify: 5,
                     after_validate: 4
    end
  end
end
