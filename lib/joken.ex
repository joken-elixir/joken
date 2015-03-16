defmodule Joken do
  use GenServer
  alias Joken.Token
  alias Joken.Utils

  @type algorithm :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error
  @type payload :: map | Keyword.t

  @doc """
  Starts a Joken server by looking for the settings in the given config block or
  Starts a Joken server with the given configuration map.

  `algorithm` is optional and defaults to `:HS256`

      config :my_otp_app, secret_key: "test", algorithm: :HS256, json_module: TestPoison

      Joken.start_link(:my_otp_app)

      #or

      config = %{secret_key: "test", algorithm: :HS256, json_module: TestJsx}
      Joken.start_link(config)   
  """
  @spec start_link(atom) :: { status, pid }
  def start_link(otp_app) when is_atom(otp_app) do
    secret_key =  Application.get_env(otp_app, :secret_key)
    json_module = Application.get_env(otp_app, :json_module)
    algorithm =   Application.get_env(otp_app, :algorithm, :HS256)
    
    start_link(secret_key, json_module, algorithm)
  end

  @spec start_link(map) :: { status, pid }
  def start_link(config) when is_map(config) do
    config = Map.put_new(config, :algorithm, :HS256)

    case Map.has_key?(Utils.supported_algorithms, config.algorithm) do
      true ->
        GenServer.start_link(__MODULE__, config)
      _ ->
        {:error, "Unsupported algorithm"}       
    end
  end

  @doc """
  Starts a Joken server with the given parameters

      Joken.start_link("test", TestJsx, :HS256)
  """
  @spec start_link(binary, module, algorithm) :: { status, pid }
  def start_link(secret_key, json_module, algorithm \\ :HS256) do
    config = %{secret_key: secret_key, algorithm: algorithm, json_module: json_module}

    start_link(config)
  end

  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

      Joken.encode(joken_pid, %{ name: "John Doe" }, %{ iss: "self"})
  """

  @spec encode(pid, payload, payload) :: { status, String.t }
  def encode(pid, payload, claims \\ %{}) do
    config = config(pid)
    secret_key = config.secret_key
    json_module = config.json_module
    algorithm = config.algorithm

    Token.encode(secret_key, json_module, payload, algorithm, claims)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload. Optionally checks against
  the given claims for validity

      Joken.decode(joken_pid, token, %{ aud: "self" })
  """

  @spec decode(pid, String.t, payload) :: { status, map | String.t }
  def decode(pid, jwt, claims \\ %{}) do
    config = config(pid)
    Token.decode(config.secret_key, config.json_module, jwt, claims)
  end

  @doc false
  @spec config(pid) :: map
  def config(pid) do
    GenServer.call(pid, :get_configuration)
  end

  def init(config) do
    {:ok, config}
  end

  @doc false
  def handle_call(:get_configuration, _from, config) do
    {:reply, config, config}
  end
  
end