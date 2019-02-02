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
        validate: fn val, _claims, _context -> val < Joken.Config.current_time() end  
      }}

  Since this is cumbersome and error prone, you can use this module with a more fluent API, see:
    - `default_claims/1`
    - `add_claim/4`

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

  It will also add `use Joken.Hooks` so you can easily hook into Joken's lifecycle.

  ## Overriding functions

  All callbacks in `Joken.Config` and `Joken.Hooks` are overridable. This can be used for 
  customizing the token configuration. All that is needed is to override the `token_config/0`
  function returning your map of binary keys to `Joken.Claim` structs. Example from the 
  benchmark suite:

      defmodule MyCustomClaimsAuth do
        use Joken.Config

        @impl true
        def token_config do
          %{} # empty claim map
          |> add_claim("name", fn -> "John Doe" end, &(&1 == "John Doe"))
          |> add_claim("test", fn -> true end, &(&1 == true))
          |> add_claim("age", fn -> 666 end, &(&1 > 18))
          |> add_claim("simple time test", fn -> 1 end, &(Joken.current_time() > &1))
        end
      end

  ## Customizing default generated claims

  The default claims generation is just a bypass call to `default_claims/1`. If one would
  like to customize it, then we need only to override the token_config function:

      defmodule MyCustomDefaults do
        use Joken.Config

        def token_config, do: default_claims(default_exp: 60 * 60) # 1 hour
      end

  ## Options

  You can pass some options to `use Joken.Config` to ease on your configuration:

    - default_signer: a signer configuration key in config.exs (see `Joken.Signer`)
  """
  import Joken, only: [current_time: 0]
  alias Joken.Signer

  @default_generated_claims [:exp, :iat, :nbf, :iss, :aud, :jti]

  @doc """
  Defines the `t:Joken.token_config/0` used for all the operations in this module.

  The default implementation is just a bypass call to `default_claims/1`.
  """
  @callback token_config() :: Joken.token_config()

  @doc """
  Generates a JWT claim set.

  Extra claims must be a map with keys as binaries. Ex: %{"sub" => "some@one.com"}
  """
  @callback generate_claims(extra :: Joken.claims()) ::
              {:ok, Joken.claims()} | {:error, Joken.error_reason()}

  @doc """
  Encodes the given map of claims to JSON and signs it.

  The signer used will be (in order of preference):

    1. The one represented by the key passed as second argument. The signer will be 
    parsed from the configuration. 
    2. If no argument was passed then we will use the one from the configuration 
    `:default_signer` passed as argument for the `use Joken.Config` macro.
    3. If no key was passed for the use macro then we will use the one configured as 
    `:default_signer` in the configuration.
  """
  @callback encode_and_sign(Joken.claims(), Joken.signer_arg() | nil) ::
              {:ok, Joken.bearer_token(), Joken.claims()} | {:error, Joken.error_reason()}

  @doc """
  Verifies token's signature using a Joken.Signer.

  The signer used is (in order of precedence):

  1. The signer in the configuration with the given `key`.
  2. The `Joken.Signer` instance passed to the method.
  3. The signer passed in the `use Joken.Config` through the `default_signer` key.
  4. The default signer in configuration (the one with the key `default_signer`).

  It returns either:

  - `{:ok, claims_map}` where claims_map is the token's claims.
  - `{:error, [message: message, claim: key, claim_val: claim_value]}` where message can be used
  on the frontend (it does not contain which claim nor which value failed).
  """
  @callback verify(Joken.bearer_token(), Joken.signer_arg() | nil) ::
              {:ok, Joken.claims()} | {:error, Joken.error_reason()}

  @doc """
  Runs validations on the already verified token. 
  """
  @callback validate(Joken.claims()) :: {:ok, Joken.claims()} | {:error, Joken.error_reason()}

  defmacro __using__(options) do
    quote do
      import Joken, only: [current_time: 0]
      import Joken.Config
      use Joken.Hooks

      @behaviour Joken.Config

      @hooks [__MODULE__]

      @before_compile Joken.Config

      @doc false
      def __default_signer__ do
        key = unquote(options)[:default_signer] || :default_signer
        Signer.parse_config(key)
      end

      @impl Joken.Config
      def token_config, do: default_claims()

      @impl Joken.Config
      def generate_claims(extra_claims \\ %{}),
        do: Joken.generate_claims(token_config(), extra_claims, __hooks__())

      @impl Joken.Config
      def encode_and_sign(claims, signer \\ nil)

      def encode_and_sign(claims, nil),
        do: Joken.encode_and_sign(claims, __default_signer__(), __hooks__())

      def encode_and_sign(claims, signer),
        do: Joken.encode_and_sign(claims, signer, __hooks__())

      @impl Joken.Config
      def verify(bearer_token, key \\ nil)

      def verify(bearer_token, nil),
        do: Joken.verify(bearer_token, __default_signer__(), __hooks__())

      def verify(bearer_token, signer),
        do: Joken.verify(bearer_token, signer, __hooks__())

      @impl Joken.Config
      def validate(claims, context \\ %{}),
        do: Joken.validate(token_config(), claims, context, __hooks__())

      defoverridable token_config: 0,
                     generate_claims: 1,
                     encode_and_sign: 2,
                     verify: 2,
                     validate: 1

      @doc "Combines `generate_claims/1` and `encode_and_sign/2`"
      @spec generate_and_sign(Joken.claims(), Joken.signer_arg()) ::
              {:ok, Joken.bearer_token(), Joken.claims()} | {:error, Joken.error_reason()}
      def generate_and_sign(extra_claims \\ %{}, key \\ __default_signer__()),
        do: Joken.generate_and_sign(token_config(), extra_claims, key, __hooks__())

      @doc "Same as `generate_and_sign/2` but raises if error"
      @spec generate_and_sign!(Joken.claims(), Joken.signer_arg()) ::
              Joken.bearer_token() | no_return()
      def generate_and_sign!(extra_claims \\ %{}, key \\ __default_signer__()),
        do: Joken.generate_and_sign!(token_config(), extra_claims, key, __hooks__())

      @doc "Combines `verify/2` and `validate/1`"
      @spec verify_and_validate(Joken.bearer_token(), Joken.signer_arg(), term) ::
              {:ok, Joken.claims()} | {:error, Joken.error_reason()}
      def verify_and_validate(bearer_token, key \\ __default_signer__(), context \\ %{}),
        do: Joken.verify_and_validate(token_config(), bearer_token, key, context, __hooks__())

      @doc "Same as `verify_and_validate/2` but raises if error"
      @spec verify_and_validate!(Joken.bearer_token(), Joken.signer_arg(), term) ::
              Joken.claims() | no_return()
      def verify_and_validate!(bearer_token, key \\ __default_signer__(), context \\ %{}),
        do: Joken.verify_and_validate!(token_config(), bearer_token, key, context, __hooks__())
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __hooks__, do: @hooks
    end
  end

  @doc """
  Adds the given hook to the list of hooks passed to all operations in this module.

  When using `use Joken.Config` in a module, this already adds the module as a hook.
  So, if you want to only override one lifecycle callback, you can simply override it
  on the module that uses `Joken.Config`.
  """
  defmacro add_hook(hook_module, options \\ []) do
    quote do
      @hooks [unquote({hook_module, options}) | @hooks]
    end
  end

  @doc """
  Initializes a map of `Joken.Claim`s with "exp", "iat", "nbf", "iss", "aud" and "jti". 

  Default parameters can be customized with options:

  - skip: do not include claims in this list. Ex: [:iss, :aud]
  - default_exp: changes the default expiration of the token. Default is 2 hours
  - iss: changes the issuer claim. Default is "Joken" 
  - aud: changes the audience claim. Default is "Joken"
  """
  @spec default_claims(Keyword.t()) :: Joken.token_config()
  # credo:disable-for-next-line
  def default_claims(options \\ []) do
    skip = options[:skip] || []
    default_exp = options[:default_exp] || 2 * 60 * 60
    default_iss = options[:iss] || "Joken"
    default_aud = options[:aud] || "Joken"
    generate_jti = options[:generate_jti] || (&Joken.generate_jti/0)

    unless is_integer(default_exp) and is_binary(default_iss) and is_binary(default_aud) and
             is_function(generate_jti) and is_list(skip) do
      raise Joken.Error, :invalid_default_claims
    end

    generate_config(skip, default_exp, default_iss, default_aud, generate_jti)
  end

  defp generate_config(skip, default_exp, default_iss, default_aud, generate_jti) do
    gen_exp_func = fn -> current_time() + default_exp end

    Enum.reduce(@default_generated_claims, %{}, fn claim, acc ->
      if claim in skip do
        acc
      else
        case claim do
          :exp ->
            add_claim(acc, "exp", gen_exp_func, &(&1 > current_time()))

          :iat ->
            add_claim(acc, "iat", fn -> current_time() end)

          :nbf ->
            add_claim(acc, "nbf", fn -> current_time() end, &(current_time() >= &1))

          :iss ->
            add_claim(acc, "iss", fn -> default_iss end, &(&1 == default_iss))

          :aud ->
            add_claim(acc, "aud", fn -> default_aud end, &(&1 == default_aud))

          :jti ->
            add_claim(acc, "jti", generate_jti)
        end
      end
    end)
  end

  @doc """
  Adds a `Joken.Claim` with the given claim key to a map.

  This is a convenience builder function. It does exactly what this example does:

      iex> config = %{}
      iex> generate_fun = fn -> "Hi" end
      iex> validate_fun = &(&1 =~ "Hi")
      iex> claim = %Joken.Claims{generate: generate_fun, validate: validate_fun}
      iex> config = Map.put(config, "claim key", claim)
  """
  @spec add_claim(Joken.token_config(), binary, fun | nil, fun | nil, Keyword.t()) ::
          Joken.token_config()
  def add_claim(config, claim_key, generate_fun \\ nil, validate_fun \\ nil, options \\ [])

  def add_claim(config, claim_key, nil, nil, _options)
      when is_map(config) and is_binary(claim_key) do
    raise Joken.Error, :claim_configuration_not_valid
  end

  def add_claim(config, claim_key, generate_fun, validate_fun, options)
      when is_map(config) and is_binary(claim_key) do
    validate_fun = if validate_fun, do: wrap_validate_fun(validate_fun), else: validate_fun

    claim = %Joken.Claim{generate: generate_fun, validate: validate_fun, options: options}
    Map.put(config, claim_key, claim)
  end

  # This ensures that all validate functions are called with arity 2 and gives some
  # more helpful message in case of errors
  defp wrap_validate_fun(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)

    case arity do
      1 ->
        fn val, _claims, _ctx -> fun.(val) end

      2 ->
        fn val, claims, _ctx -> fun.(val, claims) end

      3 ->
        fun

      _ ->
        raise Joken.Error, :bad_validate_fun_arity
    end
  end
end
