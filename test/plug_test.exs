defmodule JokenPlug.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  import Joken
  alias Joken.Token

  setup_all do
    JOSE.JWA.crypto_fallback(true)
    :ok
  end

  defmodule MyPlugRouter do
    use Plug.Router

    @skip_auth private: %{joken_skip: true}
    @is_subject private: %{joken_verify: &MyPlugRouter.is_subject/0}
    @is_not_subject private: %{joken_verify: &MyPlugRouter.is_not_subject/0}
    @is_subject_dep private: %{joken_on_verifying: &MyPlugRouter.is_subject/0}
    @is_not_subject_dep private: %{joken_on_verifying: &MyPlugRouter.is_not_subject/0}

    plug :match
    plug Joken.Plug,
      verify:   &MyPlugRouter.verify/0,
      on_error: &MyPlugRouter.error_logging/2
    plug :dispatch

    post "/generate_token", @skip_auth do

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

    get "/skip_verification", @skip_auth do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end

    post "/custom_function_success", @is_subject do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end

    post "/custom_function_failure", @is_not_subject do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end

    post "/custom_function_success_dep", @is_subject_dep do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end

    post "/custom_function_failure_dep", @is_not_subject_dep do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "I am subject 1234567890")
    end

    match _, @skip_auth do
      conn
      |> send_resp(404, "Not found")
    end

    def is_subject() do
      %Token{}
      |> with_json_module(Poison)
      |> with_validation("sub", &(&1 == 1234567890))
      |> with_signer(hs256("secret"))
    end

    def is_not_subject() do
      %Token{}
      |> with_json_module(Poison)
      |> with_validation("sub", &(&1 != 1234567890))
      |> with_signer(hs256("secret"))
    end

    def error_logging(conn, message) do
      {conn, message}
    end

    def verify() do
      %Token{}
      |> with_json_module(Poison)
      |> with_signer(hs256("secret"))
      |> with_sub(1234567890)
    end
  end

  defmodule CustomErrorBodyRouter do
    use Plug.Router

    plug Joken.Plug, verify: &CustomErrorBodyRouter.verify/1,
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

    def verify() do
      %Token{}
      |> with_json_module(Poison)
      |> with_signer(hs256("secret"))
      |> with_sub(1234567890)
    end
  end

  defmodule OnVerifyingRouter do
    use Plug.Router

    plug :match
    plug Joken.Plug, on_verifying: &OnVerifyingRouter.verify/0
    plug :dispatch

    get "/verify_token" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end

    def verify() do
      %Token{}
      |> with_json_module(Poison)
      |> with_signer(hs256("secret"))
    end
  end

  defmodule BothVerifyRouter do
    use Plug.Router

    plug :match
    plug Joken.Plug, verify:       &BothVerifyRouter.verify/0,
                     on_verifying: &BothVerifyRouter.verify/0
    plug :dispatch


    get "/verify_token" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end

    def verify() do
      %Token{}
      |> with_json_module(Poison)
      |> with_signer(hs256("secret"))
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

  test "generates token properly with deprecated on_verifying" do
    token = simple_binary_token

    conn = conn(:get, "/verify_token")
    |> put_req_header("authorization", "Bearer " <> token)
    |> OnVerifyingRouter.call([])

    assert conn.status == 200
    assert conn.resp_body == "Hello Tester"
  end

  test "generates token properly with both verify options supplied" do
    token = simple_binary_token

    conn = conn(:get, "/verify_token")
    |> put_req_header("authorization", "Bearer " <> token)
    |> BothVerifyRouter.call([])

    assert conn.status == 200
    assert conn.resp_body == "Hello Tester"
  end

  test "evaluates custom function for route deprecated (success)" do
    token = simple_binary_token

    conn = conn(:post, "/custom_function_success_dep")
    |> put_req_header("authorization", "Bearer " <> token)
    |> MyPlugRouter.call([])

    assert conn.status == 200
    assert conn.resp_body == "I am subject 1234567890"
  end

  test "evaluates custom function for route deprecated (failure)" do
    token = simple_binary_token

    conn = conn(:post, "/custom_function_failure_dep")
    |> put_req_header("authorization", "Bearer " <> token)
    |> MyPlugRouter.call([])

    assert conn.status == 401
    assert conn.resp_body == "Invalid payload"
  end

  defp simple_binary_token do
    token()
    |> with_sub(1234567890)
    |> sign(hs256("secret"))
    |> get_compact
  end

end
