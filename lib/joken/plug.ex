if Code.ensure_loaded?(Plug.Conn) do

  defmodule Joken.Plug do
    import Joken
    alias Joken.Token
    require Logger

    @moduledoc """
    A Plug for signing and verifying authentication tokens.

    ## Usage

    There are two possible scenarios:

    1. Same configuration for all routes
    2. Per route configuration

    In the first scenario just add this plug before the dispatch plug.

        defmodule MyRouter do
          use Plug.Router

          plug Joken.Plug, verify: &verify_function/1
          plug :match
          plug :dispatch

          post "/user" do
            # will only execute here if token is present and valid
          end

          match _ do
            # will only execute here if token is present and valid
          end
        end

    In the second scenario, you will need at least plug ~> 0.14 in your deps.
    Then you must plug this AFTER :match and BEFORE :dispatch.

        defmodule MyRouter do
          use Plug.Router

          # route options
          @skip_token_verification %{joken_skip: true}

          plug :match
          plug Joken.Plug, config_module: MyJWTConfig
          plug :dispatch

          post "/user" do
            # will only execute here if token is present and valid
          end

          # see options section below
          match _, private: @skip_token_verification do
            # will NOT try to validate a token
          end
        end

    ## Options

    This plug accepts the following options in its initialization:

    - `verify`: a function used to verify the token. Receives a Token and must return a Token

    - `on_error` (optional): a function that will be called with `conn` and `message`. Must
    return a tuple containing the conn and a binary representing the 401 response. If it's a map,
    it will be turned into json, otherwise, it will be returned as is.

    When using this with per route options you must pass a private map of options
    to the route. The keys that Joken will look for in that map are:

    - `joken_skip`: skips token validation

    - `joken_verify`: Same as `verify` above. Overrides
    `verify` if it was defined on the Plug

    - `joken_on_error`: Same as `on_error` above. Overrides
    `on_error` if it was defined on the Plug
    """
    import Plug.Conn

    @doc false
    def init(opts) do
      verify   = get_verify(opts)
      on_error = Keyword.get(opts, :on_error, &Joken.Plug.default_on_error/2)
      {verify, on_error}
    end

    @doc false
    def call(conn, { verify, on_error }) do

      unless Map.has_key?(conn.private, :joken_verify) do
        conn = set_joken_verify(conn, verify)
      end

      unless Map.has_key?(conn.private, :joken_on_error) do
        conn = put_private(conn, :joken_on_error, on_error)
      end

      if Map.get(conn.private, :joken_skip, false) do
        conn
      else
        parse_auth(conn, get_req_header(conn, "authorization"))
      end
    end

    defp get_verify(options) do
      case Keyword.take(options, [:verify, :on_verifying]) do
        [verify: verify] -> verify
        [verify: verify, on_verifying: _] ->
          warn_on_verifying
          verify
        [on_verifying: verify] ->
          warn_on_verifying
          verify
        [] ->
          warn_supply_verify_function
          nil
      end
    end

    defp warn_on_verifying do
      Logger.warn "on_verifying is deprecated for the Joken plug and will be removed in a future version. Please use verify instead."
    end

    defp warn_supply_verify_function do
      Logger.warn "You need to supply a verify function to the Joken token."
    end

    defp set_joken_verify(conn, verify) do
      case conn.private do
        %{joken_on_verifying: deprecated_verify} ->
          warn_on_verifying
          put_private(conn, :joken_verify, deprecated_verify)
        _ ->
          put_private(conn, :joken_verify, verify)
      end
    end

    defp parse_auth(conn, ["Bearer " <> incoming_token]) do
      payload_fun = Map.get(conn.private, :joken_verify)

      verified_token = payload_fun.()
      |> with_compact_token(incoming_token)
      |> verify

      evaluate(conn, verified_token)
    end
    defp parse_auth(conn, _header) do
      send_401(conn, "Unauthorized")
    end

    defp evaluate(conn, %Token{ error: nil } = token) do
      assign(conn, :joken_claims, get_claims(token))
    end
    defp evaluate(conn, %Token{ error: message }) do
      send_401(conn, message)
    end

    defp send_401(conn, message) do
      on_error = conn.private[:joken_on_error]

      {conn, message } = case on_error.(conn, message) do
        {conn, map} when is_map(map) ->
          create_json_response(conn, map)
        response ->
          response
      end

      conn
      |> send_resp(401, message)
      |> halt
    end

    defp create_json_response(conn, map) do
      conn = put_resp_content_type(conn, "application/json")
      json = Poison.encode!(map)
      {conn, json}
    end

    @doc false
    def default_on_error(conn, message) do
      { conn, message }
    end
  end
end
