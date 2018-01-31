defmodule Joken.Config do
  @moduledoc ~S"""
  Main entry point for configuring Joken. This module has two approaches:

  ## Creating a map of Joken.Claim s

  If you prefer to avoid using macros, you can create your configuration manually. Joken's 
  configuration is just a map with keys being binaries (the claim name) and the value an
  instance of `Joken.Claim`. 

  Example:
    
      %{"exp" => %Joken.Claim{
        generate: fn -> Joken.Config.current_time() + (2 * 60 * 60) end,
        validate: &(&1 < Joken.Config.current_time())  
      }}

  Since this is cumbersome and error prone, you can use this module with a more fluent API, see:
    - default_claims/1
    - add_claim/4

  ## Automatically load and generate functions (recommended)

  Another approach is to just `use Joken.Config` in a module. This will load a signer configuration 
  (from config.exs) and a map of `Joken.Claim` s. 

  Example:

      defmodule MyAuth do
        use Joken.Config
      end

  This way, `Joken.Config` will implement some functions for you:

    - `generate_and_sign/2`
    - `verify_and_validate/2`
    - `token_config/0`

  ## Overriding functions

  All callbacks in `Joken.Config` are overridable. This can be used for customizing the token
  configuration. All that is needed is to override the `token_config/0` function returning your map
  of binary keys to `Joken.Claim` structs. Example from the benchmark suite:

      defmodule MyCustomClaimsAuth do
        use Joken.Config

        def token_config do
          %{}
          |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
          |> add_claim("test", fn -> true end, &(&1 == true))
          |> add_claim("age", fn -> 666 end, &(&1 > 18))
          |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
        end
      end

  ## Options

  You can pass some options to `use Joken.Config` to ease on your configuration:

    - default_signer: a signer configuration key in config.exs (see Joken.Signer)

  Also, all options from `default_claims/1` can be passed. These are used in the default
  `token_config/0` implementation. If you override the function `token_config/0` then these
  options are ignored.

  It is easy to configure your token generation and validation this way:

      defmodule MyAuth do
        use Joken.Config, default_signer: :rs256

        def token_config do
          default_claims(default_exp: 8 * 60 * 60)
          |> add_claim(
              "custom",
                fn -> "My generate function" end, 
                &("This is my validate function with param #{&1} from token")
             ) 
        end
  """
  import Joken, only: [current_time: 0]
  alias Joken.{Signer, Claim}

  @default_generated_claims [:exp, :iat, :nbf, :iss]

  @callback token_config() :: Map.t()

  @doc "See Joken.Config.generate_and_sign/3 for the default implementation"
  @callback generate_and_sign(extra_claims :: Map.t(), key :: atom() | nil) :: binary()

  @doc "See Joken.Config.verify_and_validate/3 for the default implementation"
  @callback verify_and_validate(bearer_token :: binary(), key :: atom | nil) :: Map.t()

  @doc false
  defmacro __using__(options) do
    quote do
      import Joken, only: [current_time: 0]
      import Joken.Config
      alias Joken.{Signer, Claim}

      @behaviour Joken.Config

      @joken_using_args unquote(options)

      key = Keyword.get(@joken_using_args, :default_key, :default_key)
      @joken_default_signer Joken.Signer.parse_config(key)

      def __default_signer__, do: @joken_default_signer

      @impl Joken.Config
      def token_config, do: default_claims(@joken_using_args)

      @doc "See Joken.Config.generate_and_sign/3 for the default implementation"
      @impl Joken.Config
      def generate_and_sign(extra_claims \\ %{}, key \\ nil)
          when is_map(extra_claims) and is_atom(key),
          do: Joken.Config.generate_and_sign(__MODULE__, extra_claims, key)

      @doc "See Joken.Config.verify_and_validate/3 for the default implementation"
      @impl Joken.Config
      def verify_and_validate(bearer_token, key \\ nil)
          when is_binary(bearer_token) and is_atom(key),
          do: Joken.Config.verify_and_validate(__MODULE__, bearer_token, key)

      defoverridable token_config: 0, generate_and_sign: 2, verify_and_validate: 2

      @doc "Same as verify_and_update/2 but raises if error"
      def verify_and_validate!(extra_claims \\ %{}, key \\ nil) do
        {status, result} = verify_and_validate(extra_claims, key)

        case status do
          :ok ->
            result

          :error ->
            raise(Joken.Error, :claim_not_valid)
        end
      end
    end
  end

  @doc """
  Verifies token's signature using a Joken.Signer.

  The signer used is (in order of precedence):

  1. The signer in the configuration with the given `key`.
  2. The signer passed in the `use Joken.Config` through the `default_signer` key.
  3. The default signer in configuration (the one with the key `default_signer`).

  It returns either:

  - `{:ok, claims_map}` where claims_map is the token's claims.
  - `{:error, [message: message, claim: key, claim_val: claim_value]}` where message can be used
  on the frontend (it does not contain which claim nor which value failed).
  """
  def verify_and_validate(mod, bearer_token, key) do
    require Logger

    signer = parse_signer(mod, key)
    claim_map = Signer.verify(bearer_token, signer)

    config = mod.token_config()

    result =
      Enum.reduce_while(claim_map, nil, fn {key, claim_val}, _acc ->
        # When there is a function for validating the token
        with %Claim{validate: val_func} when not is_nil(val_func) <- config[key],
             true <- val_func.(claim_val) do
          {:cont, :ok}
        else
          # When there is no configuration for the claim
          nil ->
            {:cont, :ok}

          # When there is a configuration but not validation function
          %Claim{validate: nil} ->
            {:cont, :ok}

          # When it fails validation
          false ->
            Logger.debug(fn ->
              """
              Claim %{"#{key}" => #{inspect(claim_val)}} did not pass validation.

              Current time: #{inspect(Joken.current_time())}
              """
            end)

            {:halt, {:error, key, claim_val}}
        end
      end)

    case result do
      :ok ->
        {:ok, claim_map}

      {:error, key, claim_val} ->
        {:error, message: "Invalid token", claim: key, claim_val: claim_val}
    end
  end

  @doc """
  Generates a JWT claim set, encode it and then sign it.

  The signer used will be (in order of preference):

    1. The one represented by the key passed as second argument. The signer will be 
    parsed from the configuration. 
    2. If no argument was passed then we will use the one from the configuration default_signer
     passed as argument for the `use Joken.Config` macro.
    3. If no key was passed for the use macro then we will use the one configured as 
    default_signer in the configuration.

  Extra claims must be a map with keys as binaries. Ex: %{"sub" => "some@one.com"}
  """
  def generate_and_sign(mod, extra_claims \\ %{}, key \\ nil) do
    claims_config = mod.token_config()
    claims = Enum.reduce(claims_config, extra_claims, &Claim.__generate_claim__/2)
    signer = parse_signer(mod, key)
    Signer.sign(claims, signer)
  end

  @doc """
  Initializes a map of `Joken.Claim`s with "exp", "iat", "nbf" and "iss". 

  Default parameters can be customized with options:

  - skip: do not include claims in this list. Ex: ["iss"]
  - default_exp: changes the default expiration of the token. Default is 2 hours
  - iss: changes the issuer claim. Default is "Joken" 
  """
  def default_claims(options \\ []) do
    skip = Keyword.get(options, :skip, [])
    default_exp = Keyword.get(options, :default_exp, 2 * 60 * 60)
    default_iss = Keyword.get(options, :iss, "Joken")

    Enum.reduce(@default_generated_claims, %{}, fn claim, acc ->
      if claim in skip do
        acc
      else
        case claim do
          :exp ->
            add_claim(acc, "exp", fn -> current_time() + default_exp end, &(&1 > current_time()))

          :iat ->
            add_claim(acc, "iat", fn -> current_time() end)

          :nbf ->
            add_claim(acc, "nbf", fn -> current_time() end, &(current_time() >= &1))

          :iss ->
            add_claim(acc, "iss", fn -> default_iss end, &(&1 == default_iss))
        end
      end
    end)
  end

  @doc """
  add_claim
  """
  def add_claim(config, key, generate_fun \\ nil, validate_fun \\ nil)

  def add_claim(config, key, nil, nil)
      when is_map(config) and is_atom(key),
      do: raise(Joken.Error, :claim_configuration_not_valid)

  def add_claim(config, key, generate_fun, validate_fun)
      when is_map(config) and is_binary(key) do
    claim = %Joken.Claim{generate: generate_fun, validate: validate_fun}
    Map.put(config, key, claim)
  end

  defp parse_signer(mod, key) do
    signer =
      key
      |> case do
        nil -> mod.__default_signer__()
        key -> Signer.parse_config(key)
      end

    if is_nil(signer), do: raise(Joken.Error, :no_default_signer)

    signer
  end
end
