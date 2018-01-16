defmodule Joken2.Config do
  defmacro __using__(args) do
    quote do
      import Joken2.Config
      alias Joken2.{Signer, Claim}

      @doc false
      def __token_config__ do
        options = unquote(args)
        Keyword.get(options, :token, default_claims(options))
      end

      @doc false
      def __default_signer__ do
        options = unquote(args)
        key = Keyword.get(options, :default_key, :default_key)
        Signer.parse_config(key)
      end

      def generate_and_sign(extra_claims \\ %{}, key \\ nil) do
        claims_config = __token_config__()
        claims = Enum.reduce(claims_config, extra_claims, &Claim.generate_claim/2)
        signer = parse_signer(key)
        Signer.sign(claims, signer)
      end

      defp parse_signer(key \\ nil) do
        signer =
          key
          |> case do
            nil -> __default_signer__()
            key -> Signer.parse_config(key)
          end

        if is_nil(signer), do: raise(Joken.Error, :no_default_signer)

        signer
      end
    end
  end

  def empty_claims(), do: %{}

  def default_claims(options \\ []) do
    skip = Keyword.get(options, :skip, [])
    default_exp = Keyword.get(options, :default_exp, 2 * 60 * 60)
    default_iss = Keyword.get(options, :iss, "Joken")

    %{}
    |> do_skip(skip, :exp, fn config ->
      add_claim(config, "exp", fn -> current_time() + default_exp end, &(&1 > current_time()))
    end)
    |> do_skip(skip, :iat, fn config ->
      add_claim(config, "iat", fn -> current_time() end, &(&1 <= current_time()))
    end)
    |> do_skip(skip, :nbf, fn config ->
      add_claim(config, "nbf", fn -> current_time() end, &(&1 < current_time()))
    end)
    |> do_skip(skip, :iss, fn config ->
      add_claim(config, "iss", fn -> default_iss end, &(&1 == default_iss))
    end)
  end

  defp do_skip(config, skip, key, func) do
    case key in skip do
      true ->
        config

      _ ->
        func.(config)
    end
  end

  def add_claim(config, key, generate_fun, validate_fun)
      when is_binary(key) and is_function(generate_fun) and is_function(validate_fun) and
             is_map(config) do
    claim = %Joken2.Claim{generate: generate_fun, validate: validate_fun}
    Map.put(config, key, claim)
  end

  def current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1_000_000 + secs
  end
end