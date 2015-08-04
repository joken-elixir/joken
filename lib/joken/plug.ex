defmodule Joken.Plug do

  @moduledoc """
  A Plug for signing and verifying authentication tokens.

  ## Usage
  
  There are two possible scenarios:

  1. Same configuration for all routes
  2. Per route configuration

  In the first scenario just add this plug before the dispatch plug.

      defmodule MyRouter do
        use Plug.Router

        plug Joken.Plug, config_module: MyJWTConfig
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

  - `config_module`: the `Joken.Config` implementation
  - `error_map` (optional): a function that will be called with the error message
  and must return a map. The resulting map is going to be encoded to JSON and put in the body
  of all 401 responses.

  When using this with per route options you must pass a private map of options
  to the route. The keys that Joken will look for in that map are:

  - `joken_skip`: skips token validation
  - `joken_opts`: pass this as a third parameter to `Joken.Token.decode/3`
  - `joken_evaluate`: a custom function that will be called if token is valid. 
  It will be passed the payload as the only argument and if its return is falsy, a 401 
  reply will be sent and execution is halted.
  """
  import Plug.Conn
  
  @doc false
  def init(opts) do
    config_module = Keyword.get(opts, :config_module, Application.get_env(:joken, :config_module))
    {config_module}
  end

  @doc false
  def call(conn, {config_module}) do

    conn = put_private(conn, :joken_config_module, config_module)
    
    if Map.get(conn.private, :joken_skip, false) do
      conn
    else
      parse_auth(conn, get_req_header(conn, "authorization"))
    end
  end

  def encode(conn, claims) do
    {:ok, token} = Joken.Token.encode(conn.private[:joken_config_module], claims)
    token
  end

  def error_map(description, status) do
    %{error: "Unauthorized",
      description: description,
      status_code: status}
  end

  defp parse_auth(conn, ["Bearer " <> token]) do
    options = Map.get(conn.private, :joken_opts, [])
    decoded = Joken.Token.decode(conn.private[:joken_config_module], token, options)
    evaluate(conn, decoded)
  end
  defp parse_auth(conn, _header) do
    send_401(conn, "Unauthorized")
  end

  defp evaluate(conn, {:ok, payload}) do

    conn = assign(conn, :joken_payload, payload)
    
    unless payload_fun = Map.get(conn.private, :joken_evaluate) do
      conn
    else
      if payload_fun.(payload), do: conn, else: send_401(conn, "Unauthorized")
    end
  end
  defp evaluate(conn, {:error, message}) do
    send_401(conn, message)
  end

  defp send_401(conn, message) do
    config_module = conn.private[:joken_config_module]
    json = config_module.encode(error_map(message, 401))
    
    conn
    |> put_req_header("content-type", "application/json")
    |> send_resp(401, json)
    |> halt
  end
  
end
