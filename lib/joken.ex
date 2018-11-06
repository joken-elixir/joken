defmodule Joken do
  @moduledoc """
  Joken is a library for working with standard JSON Web Tokens.

  It provides 4 basic operations:

  - Verify: the act of confirming the signature of the JWT;
  - Validate: processing validation logic on the set of claims;
  - Claim generation: generate dynamic value at token creation time;
  - Signature creation: encoding header and claims and generate a signature of their value.

  ## Architecture

  The core of Joken is `JOSE`, a library which provides all facilities to sign and verify tokens.
  Joken brings an easier Elixir API with some added functionality:

    - Validating claims. JOSE does not provide validation other than signature verification.
    - `config.exs` friendly. You can optionally define your signer configuration straight in your
    `config.exs`.
    - Portable configuration. All your token logic can be encapsulated in a module with behaviours.
    - Enhanced errors. Joken strives to be as informative as it can when errors happen be it at
    compilation or at validation time.
    - Debug friendly. When a token fails validation, a `Logger` debug message will show which claim
    failed validation with which value. The return value, though for security reasons, does not
    contain these information.
    - Performance. We have a benchmark suite for identifying where we can have a better performance.
    From this analysis came: Jason adapter for JOSE, redefinition of :base64url module and other
    minor tweaks.

  ## Usage

  Joken has 3 basic concepts:

    - Portable token configuration
    - Signer configuration
    - Hooks

  The portable token configuration is a map of binary keys to `Joken.Claim` structs and is used to
  dynamically generate and validate tokens.

  A signer is an instance of `Joken.Signer` that encapsulates the algorithm and the key configuration
  used to sign and verify a token.

  A hook is an implementation of the behaviour `Joken.Hooks` for easy plugging into the lifecycle of
  Joken operations.

  There are 2 forms of using Joken:

  1. Pure data structures. You can create your token configuration and signer and use them with this
  module for all 4 operations: verify, validate, generate and sign.

  ```
  iex> token_config = %{} # empty config
  iex> token_config = Map.put(token_config, "scope", %Joken.Claim{
  ...> generate_function: fn -> "user" end,
  ...> validate_function: fn val, _claims, _context -> val in ["user", "admin"] end
  ...> })
  iex> signer = Joken.Signer.create("HS256", "my secret")
  iex> claims = Joken.generate_claims(token_config, %{"extra"=> "claim"})
  iex> {:ok, jwt, claims} = Joken.encode_and_sign(claims, signer)
  ```

  2. With the encapsulated module approach using `Joken.Config`. See the docs for `Joken.Config` for
  more details.

  ```
  iex> defmodule MyAppToken do
  ...>   use Joken.Config, default_signer: :pem_rs256
  ...>
  ...>   @impl Joken.Config
  ...>   def token_config do
  ...>     default_claims()
  ...>     |> add_claim("role", fn -> "USER" end, &(&1 in ["ADMIN", "USER"]))
  ...>   end
  ...> end
  iex> {:ok, token, _claims} = MyAppToken.generate_and_sign(%{"user_id" => "1234567890"})
  iex> {:ok, _claim_map} = MyAppToken.verify_and_validate(token)
  ```
  """
  alias Joken.{Claim, Signer}
  require Logger

  @typedoc """
  A signer argument that can be a key in the configuration or an instance of `Joken.Signer`.
  """
  @type signer_arg :: atom | Joken.Signer.t()

  @typedoc "A binary representing a bearer token."
  @type bearer_token :: binary

  @typedoc "A map with binary keys that represents a claim set."
  @type claims :: %{binary => term}

  @typedoc "A portable configuration of claims for generation and validation."
  @type token_config :: %{binary => Joken.Claim.t()}

  @typedoc "Error reason which might contain dynamic data for helping understand the cause"
  @type error_reason :: atom | Keyword.t()

  # This ensures we provide an easy to setup test environment
  @current_time_adapter Application.get_env(:joken, :current_time_adapter, Joken.CurrentTime.OS)

  @doc """
  Retrieves current time in seconds.

  This implementation uses an adapter so that you can replace it on your tests. The adapter is
  set through `config.exs`. Example:

      config :joken,
        current_time_adapter: Joken.CurrentTime.OS

  See Joken's own tests for an example of how to override this with a customizable time mock.
  """
  @spec current_time() :: pos_integer
  def current_time, do: @current_time_adapter.current_time()

  @doc """
  Decodes the header of a token without validation.

  **Use this with care!** This DOES NOT validate the token signature and therefore the token might
  be invalid. The common use case for this function is when you need info to decide on which signer
  will be used. Even though there is a use case for this, be extra careful to handle data without
  validation.
  """
  @spec peek_header(bearer_token) :: {:ok, claims} | {:error, error_reason}
  def peek_header(token) when is_binary(token) do
    with {:ok, %{"protected" => protected}} <- expand(token),
         {:ok, decoded_str} <- Base.url_decode64(protected, padding: false),
         {:ok, header} <- Jason.decode(decoded_str) do
      {:ok, header}
    else
      error -> error
    end
  end

  @doc """
  Decodes the claim set of a token without validation.

  **Use this with care!** This DOES NOT validate the token signature and therefore the token might
  be invalid. The common use case for this function is when you need info to decide on which signer
  will be used. Even though there is a use case for this, be extra careful to handle data without
  validation.
  """
  @spec peek_claims(bearer_token) :: {:ok, claims} | {:error, error_reason}
  def peek_claims(token) when is_binary(token) do
    with {:ok, %{"payload" => payload}} <- expand(token),
         {:ok, decoded_str} <- Base.url_decode64(payload, padding: false),
         {:ok, claims} <- Jason.decode(decoded_str) do
      {:ok, claims}
    else
      error -> error
    end
  end

  @doc """
  Expands a signed token into its 3 parts: protected, payload and signature.

  Protected is also called the JOSE header. It contains metadata only like:
    - "typ": the token type
    - "kid": an id for the key used in the signing
    - "alg": the algorithm used to sign a token

  Payload is the set of claims and signature is, well, the signature.
  """
  def expand(signed_token) do
    case String.split(signed_token, ".") do
      [header, payload, signature] ->
        {:ok,
         %{
           "protected" => header,
           "payload" => payload,
           "signature" => signature
         }}

      _ ->
        {:error, :token_malformed}
    end
  end

  @doc """
  Default function for generating `jti` claims. This was inspired by the `Plug.RequestId` generation.
  It avoids using `strong_rand_bytes` as it is known to have some contention when running with many
  schedulers.
  """
  @spec generate_jti() :: binary
  def generate_jti do
    binary = <<
      System.system_time(:nanoseconds)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.hex_encode32(binary, case: :lower)
  end

  @doc "Combines generate with encode_and_sign"
  @spec generate_and_sign(token_config, claims, signer_arg, [module]) ::
          {:ok, bearer_token, claims} | {:error, error_reason}
  def generate_and_sign(
        token_config,
        extra_claims \\ %{},
        signer_arg \\ :default_signer,
        hooks \\ []
      ) do
    with {:ok, claims} <- generate_claims(token_config, extra_claims, hooks),
         {:ok, token, claims} <- encode_and_sign(claims, signer_arg, hooks) do
      {:ok, token, claims}
    end
  end

  @doc "Same as generate_and_sign/4 but raises if result is an error"
  @spec generate_and_sign!(token_config, claims, signer_arg, [module]) :: binary
  def generate_and_sign!(
        token_config,
        extra_claims \\ %{},
        signer_arg \\ :default_signer,
        hooks \\ []
      ) do
    result = generate_and_sign(token_config, extra_claims, signer_arg, hooks)

    case result do
      {:ok, token, _claims} ->
        token

      {:error, reason} ->
        raise Joken.Error, [:bad_generate_and_sign, reason: reason]
    end
  end

  @doc """
  Verifies a bearer_token using the given signer and executes hooks if any are given.
  """
  @spec verify(bearer_token, signer_arg, [module]) :: {:ok, claims} | {:error, error_reason}
  def verify(bearer_token, signer, hooks \\ [])

  def verify(bearer_token, nil, hooks) when is_binary(bearer_token) and is_list(hooks),
    do: verify(bearer_token, %Signer{}, hooks)

  def verify(bearer_token, signer, hooks) when is_binary(bearer_token) and is_atom(signer),
    do: verify(bearer_token, parse_signer(signer), hooks)

  def verify(bearer_token, signer = %Signer{}, hooks) when is_binary(bearer_token) do
    with {:ok, bearer_token, signer} <- before_verify(bearer_token, signer, hooks),
         :ok <- check_signer_not_empty(signer),
         result = {:ok, claim_map} <- Signer.verify(bearer_token, signer),
         status <- parse_status(result),
         {:ok, claims_map} <- after_verify(status, bearer_token, claim_map, signer, hooks) do
      {:ok, claims_map}
    end
  end

  defp check_signer_not_empty(%Signer{alg: nil}), do: {:error, :empty_signer}
  defp check_signer_not_empty(%Signer{}), do: :ok

  @doc """
  Validates the claim map with the given token configuration and the context.

  Context can by any term. It is always passed as the second argument to the validate
  function.

  It also executes hooks if any are given.
  """
  @spec validate(token_config, claims, term, [module]) :: {:ok, claims} | {:error, error_reason}
  def validate(token_config, claims_map, context \\ nil, hooks \\ []) do
    with {:ok, claims_map, config} <- before_validate(claims_map, token_config, hooks),
         status <- reduce_validations(token_config, claims_map, context),
         {:ok, claims} <- after_validate(status, claims_map, config, hooks) do
      {:ok, claims}
    end
  end

  @doc "Combines verify and validate operations"
  @spec verify_and_validate(token_config, bearer_token, signer_arg, term, [module]) ::
          {:ok, claims} | {:error, error_reason}
  def verify_and_validate(
        token_config,
        bearer_token,
        signer \\ :default_signer,
        context \\ nil,
        hooks \\ []
      ) do
    with {:ok, claims} <- verify(bearer_token, signer, hooks),
         {:ok, claims} <- validate(token_config, claims, context, hooks) do
      {:ok, claims}
    end
  end

  @doc "Same as verify_and_validate/4 but raises on error"
  @spec verify_and_validate!(token_config, bearer_token, term, [module]) :: claims
  def verify_and_validate!(
        token_config,
        bearer_token,
        signer \\ :default_signer,
        context \\ nil,
        hooks \\ []
      ) do
    result = verify_and_validate(token_config, bearer_token, signer, context, hooks)

    case result do
      {:ok, claims} ->
        claims

      {:error, reason} ->
        raise Joken.Error, [:bad_verify_and_validate, reason: reason]
    end
  end

  @doc """
  Generates claims with the given token configuration and merges them with the given extra claims.

  It also executes hooks if any are given.
  """
  @spec generate_claims(token_config, claims | nil, [module]) ::
          {:ok, claims} | {:error, error_reason}

  def generate_claims(token_config, extra \\ %{}, hooks \\ [])

  def generate_claims(token_config, nil, hooks), do: generate_claims(token_config, %{}, hooks)

  def generate_claims(token_config, extra_claims, hooks) do
    with {:ok, extra_claims, token_config} <- before_generate(extra_claims, token_config, hooks),
         claims <- Enum.reduce(token_config, extra_claims, &Claim.__generate_claim__/2),
         {:ok, claims} <- after_generate(claims, hooks) do
      {:ok, claims}
    end
  end

  @doc """
  Encodes and generates a token from the given claim map and signs the result with the given signer.

  It also executes hooks if any are given.
  """
  @spec encode_and_sign(claims, signer_arg, [module]) :: {:ok, bearer_token, claims}
  def encode_and_sign(claims, signer, hooks \\ [])

  def encode_and_sign(claims, nil, hooks),
    do: encode_and_sign(claims, %Signer{}, hooks)

  def encode_and_sign(claims, signer, hooks) when is_atom(signer),
    do: encode_and_sign(claims, parse_signer(signer), hooks)

  def encode_and_sign(claims, %Signer{} = signer, hooks) do
    with {:ok, claims, signer} <- before_sign(claims, signer, hooks),
         :ok <- check_signer_not_empty(signer),
         result = {_, token} <- Signer.sign(claims, signer),
         status <- parse_status(result),
         {:ok, token, claims} <- after_sign(status, token, claims, signer, hooks) do
      {:ok, token, claims}
    end
  end

  defp parse_status(:ok), do: :ok
  defp parse_status({:ok, _}), do: :ok
  defp parse_status({:error, _} = res), do: res

  defp parse_signer(signer_key) do
    signer = Signer.parse_config(signer_key)

    if is_nil(signer),
      do: raise(Joken.Error, :no_default_signer),
      else: signer
  end

  defp reduce_validations(_config, %{} = claims, _context) when map_size(claims) == 0 do
    :ok
  end

  defp reduce_validations(config, claim_map, context) do
    Enum.reduce_while(claim_map, nil, fn {key, claim_val}, _acc ->
      # When there is a function for validating the token
      with %Claim{validate: val_func} when not is_nil(val_func) <- config[key],
           true <- val_func.(claim_val, claim_map, context) do
        {:cont, :ok}
      else
        # When there is no configuration for the claim
        nil ->
          {:cont, :ok}

        # When there is a configuration but no validation function
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

          {:halt, {:error, message: "Invalid token", claim: key, claim_val: claim_val}}
      end
    end)
  end

  defp before_verify(bearer_token, signer, hooks) do
    run_hooks(
      hooks,
      {:ok, bearer_token, signer},
      fn hook, options, {status, bearer_token, signer} ->
        hook.before_verify(options, status, bearer_token, signer)
      end
    )
  end

  defp before_validate(claims_map, token_config, hooks) do
    run_hooks(
      hooks,
      {:ok, claims_map, token_config},
      fn hook, options, {status, claims_map, token_config} ->
        hook.before_validate(options, status, claims_map, token_config)
      end
    )
  end

  defp before_generate(extra_claims, token_config, hooks) do
    run_hooks(
      hooks,
      {:ok, extra_claims, token_config},
      fn hook, options, {status, extra_claims, token_config} ->
        hook.before_generate(options, status, extra_claims, token_config)
      end
    )
  end

  defp before_sign(claims, signer, hooks) do
    run_hooks(
      hooks,
      {:ok, claims, signer},
      fn hook, options, {status, claims, signer} ->
        hook.before_sign(options, status, claims, signer)
      end
    )
  end

  defp after_verify(status, bearer_token, claims_map, signer, hooks) do
    result =
      run_hooks(
        hooks,
        {status, bearer_token, claims_map, signer},
        fn hook, options, {status, bearer_token, claims_map, signer} ->
          hook.after_verify(options, status, bearer_token, claims_map, signer)
        end
      )

    with {:ok, _bearer_token, claims_map, _signer} <- result do
      {:ok, claims_map}
    end
  end

  defp after_validate(status, claims_map, config, hooks) do
    result =
      run_hooks(
        hooks,
        {status, claims_map, config},
        fn hook, options, {status, claims_map, config} ->
          hook.after_validate(options, status, claims_map, config)
        end
      )

    with {:ok, claims, _config} <- result do
      {:ok, claims}
    end
  end

  defp after_generate(claims, hooks) do
    run_hooks(
      hooks,
      {:ok, claims},
      fn hook, options, {status, claims} ->
        hook.after_generate(options, status, claims)
      end
    )
  end

  defp after_sign(status, bearer_token, claims, signer, hooks) do
    result =
      run_hooks(
        hooks,
        {status, bearer_token, claims, signer},
        fn hook, options, {status, bearer_token, claims, signer} ->
          hook.after_sign(options, status, bearer_token, claims, signer)
        end
      )

    with {:ok, bearer_token, claims, _signer} <- result do
      {:ok, bearer_token, claims}
    end
  end

  defp run_hooks([], args, _fun), do: args |> check_status()

  defp run_hooks(hooks, args, fun) do
    hooks
    |> Enum.reduce_while(args, fn hook, args ->
      {hook, options} = unwrap_hook(hook)

      result = fun.(hook, options, args)

      case result do
        {:cont, result} ->
          {:cont, result}

        {:halt, result} ->
          {:halt, result}

        _ ->
          {:halt, {:error, :wrong_hook_callback}}
      end
    end)
    |> check_status()
  end

  defp check_status(result) when is_tuple(result) do
    case elem(result, 0) do
      :ok ->
        result

      :error ->
        {:error, elem(result, 1)}

      # When, for example, validation fails and hooks don't change status
      {:error, _reason} = err ->
        err

      _ ->
        {:error, :wrong_hook_status}
    end
  end

  defp unwrap_hook({_hook_module, _opts} = hook), do: hook
  defp unwrap_hook(hook) when is_atom(hook), do: {hook, []}
end
