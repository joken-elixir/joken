defmodule Joken.Config do
  @moduledoc ~S"""
  Main entry point for configuring Joken. This module has two approaches:

  ## Creating a map of `Joken.Claim` s

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

    - `generate_claims/1`: generates dynamic claims and adds them to the passed map.
    - `encode_and_sign/2`: takes a map of claims, encodes it to JSON and signs it.
    - `verify/2`: check for token tampering using a signer.
    - `validate/1`: takes a claim map and a configuration to run validations.
    - `generate_and_sign/2`: combines generation and signing.
    - `verify_and_validate/2`: combines verification and validation.
    - `token_config/0`: where you customize token generation and validation.

  ## Overriding

  All generated functions can be overridden. There are other functions for plugging into the
  lifecycle of tokens. Please, see `Joken.Hooks` as a way for integrating with Joken.

  ## Overriding functions

  All callbacks in `Joken.Config` and `Joken.Hooks` are overridable. This can be used for 
  customizing the token configuration. All that is needed is to override the `token_config/0`
  function returning your map of binary keys to `Joken.Claim` structs. Example from the 
  benchmark suite:

      defmodule MyCustomClaimsAuth do
        use Joken.Config

        def token_config do
          %{} # empty claim map
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

  @default_generated_claims [:exp, :iat, :nbf, :iss, :aud, :jti]

  @type claims_config :: %{binary() => Joken.Claim.t()}
  @type claims :: %{binary() => term()}
  @type token :: binary()
  @type validate_result :: {:ok, claims()} | {:error, term()}

  @callback token_config() :: claims_config()

  @callback generate_claims(extra :: claims()) :: claims()
  @callback encode_and_sign(claims(), key :: atom() | nil) :: token()
  @callback verify(token(), key :: atom | nil) :: claims()
  @callback validate(claims()) :: claims()

  defmacro __using__(options) do
    quote do
      import Joken, only: [current_time: 0]
      import Joken.Config

      @behaviour Joken.Config

      use Joken.Hooks

      alias Joken.{Signer, Claim}

      @joken_using_args unquote(options)

      key = Keyword.get(@joken_using_args, :default_signer, :default_signer)
      @joken_default_signer Joken.Signer.parse_config(key)

      def __default_signer__, do: @joken_default_signer

      @impl Joken.Config
      def token_config, do: default_claims(@joken_using_args)

      @doc """
      Generates a JWT claim set.

      Extra claims must be a map with keys as binaries. Ex: %{"sub" => "some@one.com"}
      """
      @impl Joken.Config
      def generate_claims(extra_claims \\ %{}),
        do: Joken.Config.generate_claims(__MODULE__, extra_claims)

      @doc """
      Encodes the given map of claims to JSON and signs it.

      The signer used will be (in order of preference):

        1. The one represented by the key passed as second argument. The signer will be 
        parsed from the configuration. 
        2. If no argument was passed then we will use the one from the configuration `:default_signer`
         passed as argument for the `use Joken.Config` macro.
        3. If no key was passed for the use macro then we will use the one configured as 
        `:default_signer` in the configuration.
      """
      @impl Joken.Config
      def encode_and_sign(claims, key \\ nil),
        do: Joken.Config.encode_and_sign(__MODULE__, claims, key)

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
      @impl Joken.Config
      def verify(bearer_token, key \\ nil) when is_atom(key),
        do: Joken.Config.verify(__MODULE__, bearer_token, key)

      @doc """
      Runs validations on the already verified token. 
      """
      @impl Joken.Config
      def validate(claims), do: Joken.Config.validate(__MODULE__, claims)

      defoverridable token_config: 0,
                     generate_claims: 1,
                     encode_and_sign: 2,
                     verify: 2,
                     validate: 1

      @doc "Combines generate_claims/1 and encode_and_sign/2"
      def generate_and_sign(extra_claims \\ %{}, key \\ nil) do
        claims = generate_claims(extra_claims)
        encode_and_sign(claims, key)
      end

      @doc "Same as generate_and_sign/2 but raises if not :ok"
      def generate_and_sign!(extra_claims \\ %{}, key \\ nil) do
        {status, result} = generate_and_sign(extra_claims, key)

        case status do
          :ok ->
            result

          :error ->
            raise(Joken.Error, [:bad_encode_and_sign, result: result])
        end
      end

      @doc "Combines verify/2 and validate/1"
      def verify_and_validate(bearer_token, key \\ nil) do
        verify(bearer_token, key)
        |> validate()
      end

      @doc "Same as verify_and_update/2 but raises if error"
      def verify_and_validate!(extra_claims \\ %{}, key \\ nil) do
        {status, result} = verify_and_validate(extra_claims, key)

        case status do
          :ok ->
            result

          :error ->
            raise Joken.Error, :claim_not_valid
        end
      end
    end
  end

  def verify(mod, bearer_token, key) when is_atom(key) do
    signer = parse_signer(mod, key)
    {:ok, bearer_token, signer} = mod.before_verify(bearer_token, signer)
    claim_map = Signer.verify(bearer_token, signer)
    {:ok, claim_map} = mod.after_verify(bearer_token, claim_map, signer)
    claim_map
  end

  def validate(mod, claim_map) do
    require Logger

    config = mod.token_config()

    {:ok, claim_map, config} = mod.before_validate(claim_map, config)

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

    result =
      case result do
        :ok ->
          {:ok, claim_map}

        {:error, key, claim_val} ->
          {:error, message: "Invalid token", claim: key, claim_val: claim_val}
      end

    {:ok, result} = mod.after_validate(result, claim_map, config)

    result
  end

  def generate_claims(mod, extra_claims) when is_map(extra_claims) do
    claims_config = mod.token_config()

    # Generate
    {:ok, extra_claims, claims_config} = mod.before_generate(extra_claims, claims_config)
    claims = Enum.reduce(claims_config, extra_claims, &Claim.__generate_claim__/2)
    {:ok, claims} = mod.after_generate(claims)
    claims
  end

  def encode_and_sign(mod, claims, key) do
    # Sign
    signer = parse_signer(mod, key)
    {:ok, claims, signer} = mod.before_sign(claims, signer)
    token = Signer.sign(claims, signer)
    mod.after_sign(token, claims, signer)
  end

  @doc """
  Initializes a map of `Joken.Claim`s with "exp", "iat", "nbf", "iss", "aud" and "jti". 

  Default parameters can be customized with options:

  - skip: do not include claims in this list. Ex: ["iss"]
  - default_exp: changes the default expiration of the token. Default is 2 hours
  - iss: changes the issuer claim. Default is "Joken" 
  - aud: changes the audience claim
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

          :aud ->
            add_claim(acc, "aud", fn -> default_iss end, &(&1 == default_iss))

          :jti ->
            add_claim(acc, "jti", &Joken.generate_jti/0)
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
