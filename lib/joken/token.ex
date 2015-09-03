defmodule Joken.Token do

  @type json_module        :: module
  @type claims             :: %{binary => any}
  @type claim_function_map :: %{binary => function}
  @type error              :: binary
  @type token              :: binary
  @type signer             :: Joken.Signer.t

  @type t :: %__MODULE__{
    json_module: module,
    claims: claims,
    claims_generation: claim_function_map,
    validations: claim_function_map,
    error: error,
    token: token,
    signer: signer
  }
  
  defstruct [json_module: nil,
             claims: %{},
             claims_generation: %{},
             validations: %{},
             error: nil,
             token: nil,
             signer: nil]

end
