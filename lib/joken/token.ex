defmodule Joken.Token do

  @type json_module :: module
  @type claims      :: %{atom => any}
  @type validations :: %{atom => function}
  @type error       :: binary
  @type token       :: binary
  @type signer      :: Joken.Signer.t

  @type t :: %__MODULE__{
    json_module: module,
    claims: claims,
    validations: validations,
    error: error,
    token: token,
    signer: signer
  }
  
  defstruct [json_module: nil,
             claims: %{},
             validations: %{},
             error: nil,
             token: nil,
             signer: nil]

end
