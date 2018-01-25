defmodule Joken do
  @current_time_adapter Application.get_env(:joken, :current_time_adapter, Joken.CurrentTime.OS)

  def current_time, do: @current_time_adapter.current_time()

  def peek_header(token) when is_binary(token) do
    %JOSE.JWS{alg: {_, alg}, fields: fields} = JOSE.JWT.peek_protected(token)
    Map.put(fields, "alg", Atom.to_string(alg))
  end

  def peek_payload(token) when is_binary(token) do
    %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(token)
    fields
  end
end
