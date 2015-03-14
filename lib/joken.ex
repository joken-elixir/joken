defmodule Joken do
  use GenServer
  alias Joken.Token
  alias Joken.Utils

  @type alg :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error

  @doc """
  Starts a Joken server by looking for the settings in the given config block

  ex.
    config :my_otp_app,
      secret_key: "test",
      algorithm: :HS256,
      json_module: TestPoison

    Joken.start_link(:my_otp_app)
  """
  @spec start_link(atom) :: { status, pid }
  def start_link(otp_app) when is_atom(otp_app) do
    secret_key =  Application.get_env(otp_app, :secret_key)
    algorithm =   Application.get_env(otp_app, :algorithm)
    json_module = Application.get_env(otp_app, :json_module)
    
    start_link(secret_key, algorithm, json_module)
  end

  @doc """
  Starts a Joken server with the given configuration map

  ex.
    config = %{secret_key: "test", algorithm: :HS256, json_module: TestJsx}

    Joken.start_link(config)
  """
  @spec start_link(map) :: { status, pid }
  def start_link(config) when is_map(config) do
    case Map.has_key?(Utils.supported_algorithms, config.algorithm) do
      true ->
        GenServer.start_link(__MODULE__, config)
      _ ->
        {:error, "Unsupported algorithm"}       
    end

    GenServer.start_link(__MODULE__, config)
  end

  @doc """
  Starts a Joken server with the given parameters

  ex.
    Joken.start_link("test", :HS256, TestJsx)
  """
  @spec start_link(binary, atom, module) :: { status, pid }
  def start_link(secret_key, algorithm, json_module) do
    config = %{secret_key: secret_key, algorithm: algorithm, json_module: json_module}

    start_link(config)
  end

  @doc """
  Encodes the given payload and optional claims into a JSON Web Token

  ex.
    Joken.encode(joken_pid, %{ name: "John Doe" }, %{ iss: "self"})
  """
  def encode(pid, payload, claims \\ %{}) do
    config = config(pid)
    secret_key = config.secret_key
    json_module = config.json_module
    algorithm = config.algorithm

    Token.encode(secret_key, algorithm, json_module, payload, claims)
  end

  @doc """
  Decodes the given JSON Web Token and gets the payload. Optionally checks against
  the given claims for validity

  ex.
    Joken.decode(joken_pid, token, %{ aud: "self" })
  """
  def decode(pid, jwt, claims \\ %{}) do
    config = config(pid)
    Token.decode(config.secret_key, config.json_module, jwt, claims)
  end

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