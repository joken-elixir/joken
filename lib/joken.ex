defmodule Joken do
  use GenServer
  alias Joken.Utils
  alias Joken.Claims

  @type alg :: :HS256 | :HS384 | :HS512
  @type status :: :ok | :error
  @supported_algorithms %{ HS256: :sha256 , HS384: :sha384, HS512: :sha512 }

  @spec start_link(atom) :: { status, pid }
  def start_link(otp_app) when is_atom(otp_app) do
    secret_key =  Application.get_env(otp_app, :secret_key)
    algorithm =   Application.get_env(otp_app, :algorithm)
    json_module = Application.get_env(otp_app, :json_module)
    
    start_link(secret_key, algorithm, json_module)
  end

  @spec start_link(map) :: { status, pid }
  def start_link(config) when is_map(config) do
    case Map.has_key?(@supported_algorithms, config.algorithm) do
      true ->
        GenServer.start_link(__MODULE__, config)
      _ ->
        {:error, "Unsupported algorithm"}       
    end

    GenServer.start_link(__MODULE__, config)
  end

  @spec start_link(binary, atom, module) :: { status, pid }
  def start_link(secret_key, algorithm, json_module) do
    config = %{secret_key: secret_key, algorithm: algorithm, json_module: json_module}

    start_link(config)
  end

  def encode(pid, payload, claims \\ %{}) do
    config = config(pid)
    json_module = config.json_module
    algorithm = config.algorithm

    headerJSON = json_module.encode(%{ alg: to_string(algorithm), typ: :JWT })
    {status, payloadJSON} = try do {:ok, Map.merge(payload, claims) |> json_module.encode} rescue _ -> {:error, nil} end

    case status do
      :error ->
        {:error, "Error encoding Map to JSON"}
      :ok ->
        header64 = Utils.base64url_encode(headerJSON)
        payload64 = Utils.base64url_encode(payloadJSON)

        signature = :crypto.hmac(@supported_algorithms[algorithm], config.secret_key, "#{header64}.#{payload64}")
        signature64 = Utils.base64url_encode(signature)

        {:ok, "#{header64}.#{payload64}.#{signature64}"}
    end
  end

  def decode(pid, jwt, claims \\ %{}) do
    config = config(pid)

    jwt
    |> Utils.get_data(config.json_module)
    |> Claims.check_signature(@supported_algorithms, config.secret_key, config.json_module)
    |> Claims.check_exp
    |> Claims.check_nbf
    |> Claims.check_aud(Map.get(claims, :aud, nil))
    |> Claims.check_iss(Map.get(claims, :iss, nil))
    |> Claims.check_sub(Map.get(claims, :sub, nil))
    |> Utils.to_map
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