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
    From this analysis came: Jason adapter for JOSE and other minor tweaks.

  ## Usage

  Joken has 3 basic concepts:

    - Portable token claims configuration
    - Signer configuration
    - Hooks

  The portable token claims configuration is a map of binary keys to `Joken.Claim` structs and is used
  to dynamically generate and validate tokens.

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
  ...>   generate: fn -> "user" end,
  ...>   validate: fn val, _claims, _context -> val in ["user", "admin"] end
  ...> })
  iex> signer = Joken.Signer.create("HS256", "my secret")
  iex> {:ok, claims} = Joken.generate_claims(token_config, %{"extra"=> "claim"})
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
  alias Joken.{Claim, Hooks, Signer}
  require Logger

  @typedoc """
  A signer argument that can be a key in the configuration or an instance of `Joken.Signer`.
  """
  @type signer_arg :: atom | Joken.Signer.t() | nil

  @typedoc "A binary representing a bearer token."
  @type bearer_token :: binary

  @typedoc "A map with binary keys that represents a claim set."
  @type claims :: %{binary => term}

  @typedoc "A list of hooks. Can be either a list of modules or a list of tuples with modules options to pass."
  @type hooks :: [module] | [{module, any}]

  @typedoc "A portable configuration of claims for generation and validation."
  @type token_config :: %{binary => Joken.Claim.t()}

  @typedoc "Error reason which might contain dynamic data for helping understand the cause."
  @type error_reason :: atom | Keyword.t()

  @type generate_result :: {:ok, claims} | {:error, error_reason}
  @type sign_result :: {:ok, bearer_token, claims} | {:error, error_reason}
  @type verify_result :: {:ok, claims} | {:error, error_reason}
  @type validate_result :: {:ok, claims} | {:error, error_reason}

  @doc """
  Retrieves current time in seconds.

  This implementation uses an adapter so that you can replace it on your tests. The adapter is
  set through `config.exs`. Example:

      config :joken,
        current_time_adapter: Joken.CurrentTime.OS

  See Joken's own tests for an example of how to override this with a customizable time mock.
  """
  @spec current_time() :: pos_integer
  def current_time, do: current_time_adapter().current_time()

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
         {:decode64, {:ok, decoded_str}} <-
           {:decode64, Base.url_decode64(protected, padding: false)},
         header <- JOSE.json_module().decode(decoded_str) do
      {:ok, header}
    else
      {:decode64, _error} -> {:error, :token_malformed}
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
         {:decode64, {:ok, decoded_str}} <-
           {:decode64, Base.url_decode64(payload, padding: false)},
         claims <- JOSE.json_module().decode(decoded_str) do
      {:ok, claims}
    else
      {:decode64, _error} -> {:error, :token_malformed}
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
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.hex_encode32(binary, case: :lower)
  end

  @doc "Combines `generate_claims/3` with `encode_and_sign/3`"
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

  @doc "Same as `generate_and_sign/4` but raises if result is an error"
  @spec generate_and_sign!(token_config, claims, signer_arg, [module]) ::
          bearer_token | no_return()
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
  @spec verify(bearer_token, signer_arg, [module]) :: verify_result()
  def verify(bearer_token, signer, hooks \\ [])

  def verify(bearer_token, nil, hooks) when is_binary(bearer_token) and is_list(hooks),
    do: verify(bearer_token, %Signer{}, hooks)

  def verify(bearer_token, signer, hooks) when is_binary(bearer_token) and is_atom(signer),
    do: verify(bearer_token, parse_signer(signer), hooks)

  def verify(bearer_token, signer = %Signer{}, hooks) when is_binary(bearer_token) do
    with {:ok, {bearer_token, signer}} <-
           Hooks.run_before_hook(hooks, :before_verify, {bearer_token, signer}),
         :ok <- check_signer_not_empty(signer),
         result <- Signer.verify(bearer_token, signer),
         {:ok, claims_map} <-
           Hooks.run_after_hook(hooks, :after_verify, result, {bearer_token, signer}) do
      {:ok, claims_map}
    end
  end

  defp check_signer_not_empty(%Signer{alg: nil}), do: {:error, :empty_signer}
  defp check_signer_not_empty(%Signer{}), do: :ok

  @doc """
  Validates the claim map with the given token configuration and the context.

  Context can by any term. It is always passed as the second argument to the validate
  function. It can be, for example, a user struct or anything.

  It also executes hooks if any are given.
  """
  @spec validate(token_config, claims, term, hooks) :: validate_result()
  def validate(token_config, claims_map, context \\ nil, hooks \\ []) do
    with {:ok, {token_config, claims_map, context}} <-
           Hooks.run_before_hook(hooks, :before_validate, {token_config, claims_map, context}),
         result <- reduce_validations(token_config, claims_map, context),
         {:ok, _config, claims, _context} <-
           Hooks.run_after_hook(
             hooks,
             :after_validate,
             result,
             {token_config, claims_map, context}
           ) do
      {:ok, claims}
    end
  end

  @doc "Combines `verify/3` and `validate/4` operations"
  @spec verify_and_validate(token_config, bearer_token, signer_arg, term, hooks) ::
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

  @doc "Same as `verify_and_validate/5` but raises on error"
  @spec verify_and_validate!(token_config, bearer_token, signer_arg, term, hooks) ::
          claims | no_return()
  def verify_and_validate!(
        token_config,
        bearer_token,
        signer \\ :default_signer,
        context \\ nil,
        hooks \\ []
      ) do
    token_config
    |> verify_and_validate(bearer_token, signer, context, hooks)
    |> case do
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
  @spec generate_claims(token_config, claims | nil, hooks) :: generate_result
  def generate_claims(token_config, extra \\ %{}, hooks \\ [])

  def generate_claims(token_config, nil, hooks), do: generate_claims(token_config, %{}, hooks)

  def generate_claims(token_config, extra_claims, hooks) do
    with {:ok, {token_config, extra_claims}} <-
           Hooks.run_before_hook(hooks, :before_generate, {token_config, extra_claims}),
         claims <- Enum.reduce(token_config, extra_claims, &Claim.__generate_claim__/2),
         {:ok, claims} <-
           Hooks.run_after_hook(
             hooks,
             :after_generate,
             {:ok, claims},
             {token_config, extra_claims}
           ) do
      {:ok, claims}
    end
  end

  @doc """
  Encodes and generates a token from the given claim map and signs the result with the given signer.

  It also executes hooks if any are given.
  """
  @spec encode_and_sign(claims, signer_arg, hooks) :: sign_result
  def encode_and_sign(claims, signer, hooks \\ [])

  def encode_and_sign(claims, nil, hooks),
    do: encode_and_sign(claims, %Signer{}, hooks)

  def encode_and_sign(claims, signer, hooks) when is_atom(signer),
    do: encode_and_sign(claims, parse_signer(signer), hooks)

  def encode_and_sign(claims, %Signer{} = signer, hooks) do
    with {:ok, {claims, signer}} <- Hooks.run_before_hook(hooks, :before_sign, {claims, signer}),
         :ok <- check_signer_not_empty(signer),
         result <- Signer.sign(claims, signer),
         {:ok, token} <- Hooks.run_after_hook(hooks, :after_sign, result, {claims, signer}) do
      {:ok, token, claims}
    end
  end

  defp parse_signer(signer_key) do
    Signer.parse_config(signer_key) || raise(Joken.Error, :no_default_signer)
  end

  defp reduce_validations(_config, %{} = claims, _context) when map_size(claims) == 0,
    do: {:ok, claims}

  defp reduce_validations(config, claim_map, context) do
    claim_map
    |> Enum.reduce_while(nil, fn {key, claim_val}, _acc ->
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

          message = Keyword.get(config[key].options, :message, "Invalid token")
          {:halt, {:error, message: message, claim: key, claim_val: claim_val}}
      end
    end)
    |> case do
      :ok -> {:ok, claim_map}
      err -> err
    end
  end

  # This ensures we provide an easy to setup test environment
  defp current_time_adapter,
    do: Application.get_env(:joken, :current_time_adapter, Joken.CurrentTime.OS)
end
