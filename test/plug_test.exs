defmodule JokenPlug.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  import Joken

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end

  defmodule MyPlugRouter do
    use Plug.Router

    @skip_auth %{joken_skip: true}
    @is_subject %{joken_on_verifying: &MyPlugRouter.is_subject/1 }
    @is_not_subject %{joken_on_verifying: &MyPlugRouter.is_not_subject/1 }

    plug :match
    plug Joken.Plug,
      on_verifying: &MyPlugRouter.on_verifying/1,
      on_error: &MyPlugRouter.error_logging/2
    plug :dispatch

    post "/generate_token", private: @skip_auth do

      compact = token()
      |> with_sub(1234567890)
      |> sign(hs256("secret"))
      |> get_compact

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, compact)
    end
      
    get "/verify_token" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")      
    end

    get "/skip_verification", private: @skip_auth do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")      
    end

    post "/custom_function_success", private: @is_subject do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end

    post "/custom_function_failure", private: @is_not_subject do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end
    
    match _, private: @skip_auth do
      conn
      |> send_resp(404, "Not found")
    end

    def is_subject(payload) do
      payload
      |> with_validation(:sub, &(&1 == 1234567890))
      |> with_signer(hs256("secret"))
    end

    def is_not_subject(payload) do
      payload
      |> with_validation(:sub, &(&1 != 1234567890))
      |> with_signer(hs256("secret"))
    end

    def error_logging(conn, message) do
      {conn, message}
    end

    def on_verifying(payload) do
      payload
      |> with_signer(hs256("secret"))
      |> with_sub(1234567890)
    end
  end

  defmodule CustomErrorBodyRouter do
    use Plug.Router

    plug Joken.Plug, on_verifying: &CustomErrorBodyRouter.on_verifying/1, 
    on_error: &CustomErrorBodyRouter.on_error/2

    plug :match
    plug :dispatch

    post "/no_token_error" do
      _ = conn
      :ok
    end

    match _ do
      conn |> send_resp(404, "Not found")
    end

    def on_error(conn, message) do
      body = %{status: 401, message: message}
      {conn, body}
    end

    def on_verifying(payload) do
      payload
      |> with_signer(hs256("secret"))
      |> with_sub(1234567890)
    end

  end

  test "generates token properly" do
    conn = conn(:post, "/generate_token") |> MyPlugRouter.call([])
    assert conn.status == 200

    token = conn.resp_body
    
    conn = conn(:get, "/verify_token")
    |> put_req_header("authorization", "Bearer " <> token)
    |> MyPlugRouter.call([])

    assert conn.status == 200
    assert conn.resp_body == "Hello Tester"
  end
  
  test "sends 401 when credentials are missing" do
    conn = conn(:get, "/verify_token") |> MyPlugRouter.call([])
    assert conn.status == 401
    assert conn.resp_body == "Unauthorized"
  end

  test "skips verification properly" do
    conn = conn(:get, "/skip_verification") |> MyPlugRouter.call([])
    assert conn.status == 200
    assert conn.resp_body == "Hello Tester"
  end

  test "evaluates custom function for route (success)" do
    conn = conn(:post, "/generate_token") |> MyPlugRouter.call([])
    assert conn.status == 200

    token = conn.resp_body
    
    conn = conn(:post, "/custom_function_success")
    |> put_req_header("authorization", "Bearer " <> token)
    |> MyPlugRouter.call([])

    assert conn.status == 200
    assert conn.resp_body == "I am subject 1234567890"
  end

  test "evaluates custom function for route (failure)" do
    conn = conn(:post, "/generate_token") |> MyPlugRouter.call([])
    assert conn.status == 200

    token = conn.resp_body
    
    conn = conn(:post, "/custom_function_failure")
    |> put_req_header("authorization", "Bearer " <> token)
    |> MyPlugRouter.call([])

    assert conn.status == 401
    assert conn.resp_body == "Invalid payload"
  end

  test "generates custom error body" do
    conn = conn(:post, "/no_token_error") |> CustomErrorBodyRouter.call([])
    assert conn.status == 401
    assert conn.resp_body == ~s({"status":401,"message":"Unauthorized"})
  end

end
