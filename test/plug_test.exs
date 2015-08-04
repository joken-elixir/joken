defmodule JokenPlug.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule MyConfig do
    @behaviour Joken.Config

    def secret_key(), do: "secret"
    def algorithm(), do: :HS256
    def encode(map), do: Poison.encode!(map)
    def decode(binary), do: Poison.decode!(binary, keys: :atoms!)
    def claim(:sub, _), do: 1234567890
    def claim(_, _), do: nil
    def validate_claim(_, _, _), do: :ok
  end

  defmodule MyPlugRouter do
    use Plug.Router

    @skip_auth %{joken_skip: true}
    @is_subject %{joken_evaluate: &MyPlugRouter.is_subject/1 }
    @is_not_subject %{joken_evaluate: &MyPlugRouter.is_not_subject/1 }

    plug :match
    plug Joken.Plug, config_module: MyConfig
    plug :dispatch

    post "/generate_token", private: @skip_auth do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, Joken.Plug.encode(conn, %{}))      
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

    def is_subject(payload), do: payload.sub == 1234567890
    def is_not_subject(payload), do: payload.sub != 1234567890

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
    assert conn.resp_body == ~s({"status_code":401,"error":"Unauthorized","description":"Unauthorized"}) 
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
    assert conn.resp_body == ~s({"status_code":401,"error":"Unauthorized","description":"Unauthorized"}) 
  end

end
