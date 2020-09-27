defmodule Joken.Error do
  @moduledoc """
  Errors for the Joken API.
  """
  defexception [:reason]

  alias Joken.Signer

  @doc false
  def exception(reason), do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: :no_default_signer}),
    do: """
    Can't sign your token because couldn't create a signer.

    To create a signer we need a key in config.exs. You can define
    a key in your config.exs in several ways:

    1. For the default key, use `config :joken, default_signer: <key_params>`
    2. For other keys, use `config :joken, <key_name>: <key_params>`

    If you are using different than default keys, you can pass it as the second
    argument to `generate_and_sign/2` or as a parameter for `use Joken.Config`,
    example: `use Joken.Config, default_signer: <key_name>`

    See configuration docs for possible values of <key_params>.
    """

  def message(%__MODULE__{reason: [:bad_generate_and_sign, reason: result]}),
    do: """
    Error while calling `generate_and_sign!`. Reason: #{inspect(result)}.
    """

  def message(%__MODULE__{reason: [:bad_verify_and_validate, reason: result]}),
    do: """
    Error while calling `verify_and_validate!`. Reason: #{inspect(result)}.
    """

  def message(%__MODULE__{reason: :invalid_default_claims}),
    do: """
    Invalid argument to default claims. Verify the types of the arguments to
    Joken.Config.default_claims/1.
    """

  def message(%__MODULE__{reason: :algorithm_needs_key}),
    do: """
    A map was expected for the key parameter in the signer creation. 
    This is mandatory for: #{inspect(Signer.map_key_algorithms())}.
    """

  def message(%__MODULE__{reason: :unrecognized_algorithm}),
    do: """
    Couldn't recognize the signer algorithm.

    Possible values are:

    #{inspect(Signer.algorithms())}
    """

  def message(%__MODULE__{reason: :claim_not_valid}),
    do: """
    Claim did not pass validation.

    Set log level to debug for more information.
    """

  def message(%__MODULE__{reason: :claim_configuration_not_valid}),
    do: """
    Claim configuration is not valid. You must have either a generation function or a
    validation function.

    If both are nil you don`t need a Joken.Claim configuration. You can pass any map of values
    to `Joken.Config.generate_and_sign/3`. Verify will only use claims that have a validation
    function on your configuration. Example:

        defmodule CustomClaimTest do
          use Joken.Config
        end

        CustomClaimTest.generate_and_sign %{"a claim without configuration" => "any value"}
    """

  def message(%__MODULE__{reason: :bad_validate_fun_arity}),
    do: """
    Claim validate function must have either arity 1 or 2.

    When arity is 1, it receives the claim value in a given JWT.

    When it is 2, besides the claim value, it receives a context map. You can pass dynamic
    values on this context and pass it to the validate function.

    See `Joken.Config.validate/3` for more information on Context
    """

  def message(%__MODULE__{reason: :wrong_key_parameters}),
    do: """
    Couldn't create a signer because there are missing parameters.

    Check the Joken.Signer.parse_config/2 documentation for the types of parameters needed
    for each type of algorithm.
    """
end
