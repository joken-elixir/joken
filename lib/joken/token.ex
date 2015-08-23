defmodule Joken.Token do

  @type serializer :: module
  @type claims      :: %{atom => any}
  @type validations :: %{atom => function}
  @type error       :: binary
  @type token       :: binary
  @type signer      :: Joken.Signer.t

  @type t :: %__MODULE__{
    serializer: module,
    claims: claims,
    validations: validations,
    error: error,
    token: token,
    signer: signer
  }
  
  defstruct [serializer: nil,
             claims: %{},
             validations: %{},
             error: nil,
             token: nil,
             signer: nil]

end
