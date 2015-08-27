defmodule Joken do
  alias Joken.Token
  alias Joken.Signer
  import Joken.Helpers

  @moduledoc """
  Joken is the main API for configuring JWT token generation and 
  validation.

  All you need to generate a token is a `Joken.Token` struct with proper values. 
  There you can set:
  - json_module: choose your JSON library (currently supports Poison | JSX)
  - signer: a map that tells the underlying system how to sign and verify your 
  tokens
  - validations: a map of claims keys to function validations
  - claims: the map of values you want encoded in a token
  - token: the compact representation of a JWT token
  - error: message indicating why a sign/verify operation failed

  To help you fill that configuration struct properly, use the functions in this 
  module.
  """

  @doc """
  Generates a `Joken.Token` with the following defaults:
  - Poison as the json_module
  - claims: exp(now + 2 hours), iat(now), nbf(now - 100ms) and iss ("Joken")
  - validations for default :
    - with_validation(:exp, &(&1 > get_current_time))
    - with_validation(:iat, &(&1 < get_current_time))
    - with_validation(:nbf, &(&1 < get_current_time))
    - with_validation(:iss, &(&1 == "Joken"))
  """
  @spec token() :: Token.t
  def token() do
    %Token{}
    |> with_json_module(Poison)
    |> with_exp
    |> with_iat
    |> with_nbf
    |> with_validation(:exp, &(&1 > get_current_time))
    |> with_validation(:iat, &(&1 < get_current_time))
    |> with_validation(:nbf, &(&1 < get_current_time))
  end

  @doc """
  Generates a `Joken.Token` with either a custom payload or a compact token. 
  Defaults Poison as the json module.
  """
  @spec token(binary | map | Struct.t) :: Token.t
  def token(payload) when is_map(payload) do
    %Token{claims: payload}
    |> with_json_module(Poison)
  end
  def token(token) when is_binary(token) do
    %Token{token: token}
    |> with_json_module(Poison)
  end

  @doc """
  Configures the default JSON module for Joken.
  """
  @spec with_json_module(Token.t, atom) :: Token.t
  def with_json_module(token = %Token{}, module) when is_atom(module) do
    JOSE.json_module(module)
    %{ token | json_module: module }
  end

  @doc """
  Sets the given compact token into the given `Joken.Token` struct.
  """
  @spec with_compact_token(Token.t, binary) :: Token.t
  def with_compact_token(token = %Token{}, compact) when is_binary(compact) do
    %{ token | token: compact }
  end
  
  @doc """
  Adds `:exp` claim with a default value of now + 2hs.
  """
  @spec with_exp(Token.t) :: Token.t
  def with_exp(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :exp, get_current_time + (2 * 60 * 60 * 1000)) }
  end

  @doc """
  Adds `:exp` claim with a given value.
  """
  @spec with_exp(Token.t, non_neg_integer) :: Token.t
  def with_exp(token = %Token{claims: claims}, time_to_expire) do
    %{ token | claims: Map.put(claims, :exp, time_to_expire) }
  end

  @doc """
  Adds `:iat` claim with a default value of now.
  """
  @spec with_iat(Token.t) :: Token.t
  def with_iat(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :iat, get_current_time) }
  end
  @doc """
  Adds `:iat` claim with a given value.
  """
  @spec with_iat(Token.t, non_neg_integer) :: Token.t
  def with_iat(token = %Token{claims: claims}, time_issued_at) do
    %{ token | claims: Map.put(claims, :iat, time_issued_at) }
  end

  @doc """
  Adds `:nbf` claim with a default value of now - 100ms.
  """
  @spec with_nbf(Token.t) :: Token.t
  def with_nbf(token = %Token{claims: claims}) do
    %{ token | claims: Map.put(claims, :nbf, get_current_time - 100) }
  end

  @doc """
  Adds `:nbf` claim with a given value.
  """
  @spec with_nbf(Token.t, non_neg_integer) :: Token.t
  def with_nbf(token = %Token{claims: claims}, time_not_before) do
    %{ token | claims: Map.put(claims, :nbf, time_not_before) }
  end

  @doc """
  Adds `:iss` claim with a given value.
  """
  @spec with_iss(Token.t, any) :: Token.t
  def with_iss(token = %Token{claims: claims}, issuer) do
    %{ token | claims: Map.put(claims, :iss, issuer) }
  end

  @doc """
  Adds `:sub` claim with a given value.
  """
  @spec with_sub(Token.t, any) :: Token.t
  def with_sub(token = %Token{claims: claims}, sub) do
    %{ token | claims: Map.put(claims, :sub, sub) }
  end

  @doc """
  Adds `:aud` claim with a given value.
  """
  @spec with_aud(Token.t, any) :: Token.t
  def with_aud(token = %Token{claims: claims}, aud) do
    %{ token | claims: Map.put(claims, :aud, aud) }
  end

  @doc """
  Adds `:jti` claim with a given value.
  """
  @spec with_jti(Token.t, any) :: Token.t
  def with_jti(token = %Token{claims: claims}, jti) do
    %{ token | claims: Map.put(claims, :jti, jti) }
  end

  @doc """
  Adds a custom claim with a given value. The key must be an atom.
  """
  @spec with_claim(Token.t, atom, any) :: Token.t
  def with_claim(token = %Token{claims: claims}, claim_key, claim_value) when is_atom(claim_key) do
    %{ token | claims: Map.put(claims, claim_key, claim_value) }
  end

  @doc """
  Adds the given map or struct as the claims for this token
  """
  @spec with_claims(Token.t, map | Struct.t) :: Token.t
  def with_claims(token = %Token{}, claims) when is_map(claims) do
    %{ token | claims: claims }
  end

  # convenience functions

  # HMAC SHA functions
  @doc "See Joken.Signer.hs/2"
  def hs256(secret), do: Signer.hs("HS256", secret)

  @doc "See Joken.Signer.hs/2"
  def hs384(secret), do: Signer.hs("HS384", secret)

  @doc "See Joken.Signer.hs/2"
  def hs512(secret), do: Signer.hs("HS512", secret)

  # 
  @doc "See Joken.Signer.es/2"
  def es256(key), do: Signer.es("ES256", key)

  @doc "See Joken.Signer.es/2"
  def es384(key), do: Signer.es("ES384", key)

  @doc "See Joken.Signer.es/2"
  def es512(key), do: Signer.es("ES512", key)

  # RSASSA-PKCS1-v1_5 SHA
  @doc "See Joken.Signer.rs/2"
  def rs256(key), do: Signer.rs("RS256", key)

  @doc "See Joken.Signer.rs/2"
  def rs384(key), do: Signer.rs("RS384", key)

  @doc "See Joken.Signer.rs/2"
  def rs512(key), do: Signer.rs("RS512", key)

  #  RSASSA-PSS using SHA and MGF1 with SHA
  @doc "See Joken.Signer.ps/2"
  def ps256(key), do: Signer.ps("PS256", key)

  @doc "See Joken.Signer.ps/2"
  def ps384(key), do: Signer.ps("PS384", key)

  @doc "See Joken.Signer.ps/2"
  def ps512(key), do: Signer.ps("PS512", key)
  
  @doc """
  Adds a signer to a token configuration. 

  This **DOES NOT** call `sign/1`, `sign/2`, `verify/1` or `verify/2`. 
  It only sets the signer in the token configuration.
  """
  @spec with_signer(Token.t, Signer.t) :: Token.t
  def with_signer(token = %Token{}, signer = %Signer{}) do
    %{ token | signer: signer }
  end

  @doc """
  Signs a given set of claims. If signing is successful it will put the compact token in 
  the configuration's token field. Otherwise, it will fill the error field.
  """
  @spec sign(Token.t) :: Token.t
  def sign(token), do: Signer.sign(token)

  @doc """
  Same as `sign/1` but overrides any signer that was set in the configuration.
  """
  @spec sign(Token.t, Signer.t) :: Token.t
  def sign(token, signer), do: Signer.sign(token, signer)

  @doc "Convenience function to retrieve the compact token"
  @spec get_compact(Token.t) :: binary | nil
  def get_compact(%Token{token: token}), do: token

  @doc "Convenience function to retrieve the claim set"
  @spec get_claims(Token.t) :: map
  def get_claims(%Token{claims: claims}), do: claims 

  @doc """
  Adds a validation for a given claim key.

  Validation works by applying the given function passing the payload value for that key.

  If it is successful the value is added to the claims. If it fails, then it will raise an
  ArgumentError.

  If a claim in the payload has no validation, then it **WILL BE ADDED** to the claim set.
  """
  @spec with_validation(Token.t, atom, function) :: Token.t
  def with_validation(token = %Token{validations: validations}, claim, function) when is_atom(claim) and is_function(function) do

    %{ token | validations: Map.put(validations, claim, function) }
  end

  @doc """
  Runs verification on the token set in the configuration. 
  
  It first checks the signature comparing the header with the one found in the signer.

  Then it runs validations on the decoded payload. If everything passes then the configuration
  has all the claims available in the claims map.
  """
  @spec verify(Token.t) :: Token.t
  def verify(%Token{} = token), do: Signer.verify(token)
  

  @doc """
  Same as `verify/1` except overrides the Signer in the Token struct with the one defined.
  If the second parameter is not a Signer struct, it will be used to turn the claims into a
  struct using the `module` given
  """
  @spec verify(Token.t, Signer.t) :: Token.t
  def verify(%Token{} = token, %Signer{} = signer), do: Signer.verify(token, signer)

  @spec verify(Token.t, module) :: Token.t
  def verify(%Token{} = token, module), do: Signer.verify(token, token.signer, module)


  @doc """
  Verifies the given `token` using the `signer` and turns the validated claims into a struct
  using the `module`
  """
  @spec verify(Token.t, Signer.t, module) :: Token.t
  def verify(%Token{} = token, %Signer{} = signer, module), do: Signer.verify(token, signer, module)


  @doc """
  Same as `verify/1` except that it returns either: 
  - `{:ok, claims}`
  - `{:error, message}`
  """
  @spec verify!(Token.t) :: {:ok, map} | {:error, binary}
  def verify!(%Token{} = token) do
    Signer.verify(token)
    |> do_verify!
  end

  @doc """
  Same as `verify/2` except that it returns either: 
  - `{:ok, claims}`
  - `{:error, message}`
  """
  @spec verify!(Token.t, Signer.t) :: {:ok, map} | {:error, binary}
  def verify!(%Token{} = token, %Signer{} = signer) do
    Signer.verify(token, signer)
    |> do_verify!
  end

  @spec verify!(Token.t, module) :: {:ok, map} | {:error, binary}
  def verify!(%Token{} = token, module) do
    Signer.verify(token, token.signer, module)
    |> do_verify!
  end

  @doc """
  Same as `verify/3` except that it returns either: 
  - `{:ok, claims}`
  - `{:error, message}`
  """
  @spec verify!(Token.t, Signer.t, module) :: {:ok, map} | {:error, binary}
  def verify!(%Token{} = token, %Signer{} = signer, module) do
    Signer.verify(token, signer, module)
    |> do_verify!
  end

  defp do_verify!(token) do
    if token.error do
      {:error, token.error}
    else
      {:ok, token.claims }
    end
  end
end
