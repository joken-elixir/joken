defmodule Joken.Hooks.RequiredClaims do
  @moduledoc """
  Hook to demand claims presence.

  Adding this hook to your token configuration will allow to ensure some claims are present. It
  adds an `after_validate/3` implementation that checks claims presence. Example:

      defmodule MyToken do
        use Joken.Config

        add_hook Joken.Hooks.RequiredClaims, [:claim1, :claim2]
      end

  On missing claims it returns: `{:error, [message: "Invalid token", missing_claims: claims]}`.
  """
  use Joken.Hooks

  @impl Joken.Hooks
  def after_validate([], _, _) do
    raise "Missing required claims options"
  end

  def after_validate(opts, _, _) when not is_list(opts) do
    raise "Options must be a list of claim keys"
  end

  def after_validate(required_claims, {:ok, claims} = result, input) do
    required_claims = required_claims |> Enum.map(&map_keys/1) |> MapSet.new()
    claims = claims |> Map.keys() |> MapSet.new()

    required_claims
    |> MapSet.subset?(claims)
    |> case do
      true ->
        {:cont, result, input}

      _ ->
        diff = required_claims |> MapSet.difference(claims) |> MapSet.to_list()
        {:halt, {:error, [message: "Invalid token", missing_claims: diff]}}
    end
  end

  def after_validate(_, result, input), do: {:cont, result, input}

  # will raise if not binary or atom
  defp map_keys(key) when is_binary(key), do: key
  defp map_keys(key) when is_atom(key), do: Atom.to_string(key)
end
