defmodule Joken.Hooks do
  @moduledoc """
  Behaviour for defining hooks into Joken's lifecycle.

  Hooks are passed to `Joken` functions or added to `Joken.Config` through the
  `Joken.Config.add_hook/2` macro. They can change the execution flow of a token configuration.

  There are 2 kinds of hooks: before and after.

  Both of them are executed in a reduce_while call and so must always return either:
    - `{:halt, ...}` -> when you want to abort execution (other hooks won't be called)
    - `{:cont, ...}` -> when you want to let other hooks execute

  ## Before hooks

  A before hook receives as the first parameter its options and then a tuple with the input of
  the function. For example, the `generate_claims` function receives the token configuration plus a
  map of extra claims. Therefore, a `before_generate` hook receives:
    - the hook options or `[]` if none are given;
    - a tuple with two elements where the first is the token configuration and the second is the extra
    claims map;

  The return of a before hook is always the input of the next hook. Say you want to add an extra claim
  with a hook. You could do so like in this example:

      defmodule EnsureExtraClaimHook do
        use Joken.Hooks

        @impl true
        def before_generate(_hook_options, {token_config, extra_claims}) do
          {:cont, {token_config, Map.put(extra_claims, "must_exist", true)}}
        end
      end

  You could also halt execution completely on a before hook. Just use the `:halt` return with an error
  tuple:

      defmodule StopTheWorldHook do
        use Joken.Hooks

        @impl true
        def before_generate(_hook_options, _input) do
          {:halt, {:error, :stop_the_world}}
        end
      end

  ## After hooks

  After hooks work similar then before hooks. The difference is that it takes and returns the result of the
  operation. So, instead of receiving 2 arguments it takes three:
    - the hook options or `[]` if none are given;
    - the result tuple which might be `{:error, reason}` or a tuple with `:ok` and its parameters;
    - the input to the function call.

  Let's see an example with `after_verify`. The verify function takes as argument the token and a signer. So,
  an `after_verify` might look like this:

      defmodule CheckVerifyError do
        use Joken.Hooks
        require Logger

        @impl true
        def after_verify(_hook_options, result, input) do
          case result do
            {:error, :invalid_signature} ->
              Logger.error("Check signer!!!")
              {:halt, result}

            {:ok, _claims} ->
              {:cont, result, input}
          end
        end
      end

  On this example we have conditional logic for different results.

  ## `Joken.Config`

  When you create a module that has `use Joken.Config` it automatically implements
  this behaviour with overridable functions. You can simply override a callback
  implementation directly and it will be triggered when using any of the generated
  functions. Example:

      defmodule HookToken do
        use Joken.Config

        @impl Joken.Hooks
        def before_generate(_options, input) do
          IO.puts("Before generating claims")
          {:cont, input}
        end
      end

  Now if we call `HookToken.generate_claims/1` it will call our callback.

  Also in `Joken.Config` there is an imported macro for adding hooks with options. Example:

      defmodule ManyHooks do
        use Joken.Config

        add_hook(JokenJwks, jwks_url: "http://someserver.com/.well-known/certs")
      end

  For an implementation reference, please see the source code of `Joken.Hooks.RequiredClaims`
  """
  alias Joken.Signer

  @type halt_tuple :: {:halt, tuple}
  @type hook_options :: Keyword.t()
  @type generate_input :: {Joken.token_config(), extra :: Joken.claims()}
  @type sign_input :: {Joken.claims(), Signer.t()}
  @type verify_input :: {Joken.bearer_token(), Signer.t()}
  @type validate_input :: {Joken.token_config(), Joken.claims(), context :: map()}

  @doc "Called before `Joken.generate_claims/3`"
  @callback before_generate(hook_options, generate_input) :: {:cont, generate_input} | halt_tuple

  @doc "Called before `Joken.encode_and_sign/3`"
  @callback before_sign(hook_options, sign_input) :: {:cont, sign_input} | halt_tuple

  @doc "Called before `Joken.verify/3`"
  @callback before_verify(hook_options, verify_input) :: {:cont, verify_input} | halt_tuple

  @doc "Called before `Joken.validate/4`"
  @callback before_validate(hook_options, validate_input) :: {:cont, validate_input} | halt_tuple

  @doc "Called after `Joken.generate_claims/3`"
  @callback after_generate(hook_options, Joken.generate_result(), generate_input) ::
              {:cont, Joken.generate_result(), generate_input} | halt_tuple

  @doc "Called after `Joken.encode_and_sign/3`"
  @callback after_sign(
              hook_options,
              Joken.sign_result(),
              sign_input
            ) :: {:cont, Joken.sign_result(), sign_input} | halt_tuple

  @doc "Called after `Joken.verify/3`"
  @callback after_verify(
              hook_options,
              Joken.verify_result(),
              verify_input
            ) :: {:cont, Joken.verify_result(), verify_input} | halt_tuple

  @doc "Called after `Joken.validate/4`"
  @callback after_validate(
              hook_options,
              Joken.validate_result(),
              validate_input
            ) :: {:cont, Joken.validate_result(), validate_input} | halt_tuple

  defmacro __using__(_opts) do
    quote do
      @behaviour Joken.Hooks

      @impl true
      def before_generate(_hook_options, input), do: {:cont, input}

      @impl true
      def before_sign(_hook_options, input), do: {:cont, input}

      @impl true
      def before_verify(_hook_options, input), do: {:cont, input}

      @impl true
      def before_validate(_hook_options, input), do: {:cont, input}

      @impl true
      def after_generate(_hook_options, result, input), do: {:cont, result, input}

      @impl true
      def after_sign(_hook_options, result, input), do: {:cont, result, input}

      @impl true
      def after_verify(_hook_options, result, input), do: {:cont, result, input}

      @impl true
      def after_validate(_hook_options, result, input), do: {:cont, result, input}

      defoverridable before_generate: 2,
                     before_sign: 2,
                     before_verify: 2,
                     before_validate: 2,
                     after_generate: 3,
                     after_sign: 3,
                     after_verify: 3,
                     after_validate: 3
    end
  end

  @before_hooks [:before_generate, :before_sign, :before_verify, :before_validate]
  @after_hooks [:after_generate, :after_sign, :after_verify, :after_validate]

  def run_before_hook(hooks, hook_function, input) when hook_function in @before_hooks do
    hooks
    |> Enum.reduce_while(input, fn hook, input ->
      {hook, opts} = unwrap_hook(hook)

      case apply(hook, hook_function, [opts, input]) do
        {:cont, _next_input} = res -> res
        {:halt, _reason} = res -> res
        _ -> {:halt, {:error, :wrong_hook_return}}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      res -> {:ok, res}
    end
  end

  def run_after_hook(hooks, hook_function, result, input) when hook_function in @after_hooks do
    hooks
    |> Enum.reduce_while({result, input}, fn hook, {result, input} ->
      {hook, opts} = unwrap_hook(hook)

      case apply(hook, hook_function, [opts, result, input]) do
        {:cont, result, next_input} -> {:cont, {result, next_input}}
        {:halt, _reason} = res -> res
        _ -> {:halt, {:error, :wrong_hook_return}}
      end
    end)
    |> case do
      {result, input} when is_tuple(input) -> result
      res -> res
    end
  end

  defp unwrap_hook({_hook_module, _opts} = hook), do: hook
  defp unwrap_hook(hook) when is_atom(hook), do: {hook, []}
end
