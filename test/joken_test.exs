defmodule JokenTest do
  use ExUnit.Case

  defp get_current_time() do
    {mega, secs, _} = :os.timestamp()
    mega * 1000000 + secs
  end

  test "encode and decode with HS256" do
    payload = %{ sub: 1234567890, name: "John Doe", admin: true }
    {:ok, token} = Joken.encode(payload, "secret", :HS256, %{})
    assert(token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwibmFtZSI6IkpvaG4gRG9lIiwic3ViIjoxMjM0NTY3ODkwfQ.ZpiBS4-dQHwYOMPXl22ja8cKKoCsOqM7J5fB_YeklDI")

    {:ok, decoded_payload} = Joken.decode(token, "secret") 
    assert(payload == decoded_payload) 
  end

  test "encode and decode with HS384" do
    payload = %{ sub: 1234567890, name: "John Doe", admin: true }
    {:ok, token} = Joken.encode(payload, "secret", :HS384, %{})
    assert(token == "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwibmFtZSI6IkpvaG4gRG9lIiwic3ViIjoxMjM0NTY3ODkwfQ.fwd0LqrNq-IdUXQJ7nkPTKPJBCwoLOTcoU7tX6Qcfcxt-gVbhw0tFz7R0H8Y4Yuu")

    {:ok, decoded_payload} = Joken.decode(token, "secret") 
    assert(payload == decoded_payload) 
  end

  test "encode and decode with HS512" do
    payload = %{ sub: 1234567890, name: "John Doe", admin: true }
    {:ok, token} = Joken.encode(payload, "secret", :HS512, %{})
    assert(token == "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZSwibmFtZSI6IkpvaG4gRG9lIiwic3ViIjoxMjM0NTY3ODkwfQ.3rP7ZSSFHS55AWzaNLsRASiEBT1q0gXC9ZxioJtmrQ_wrIYPUOZP2LC_wuGK8i5vGVxVa2dDGMdXEq6geltF1w")

    {:ok, decoded_payload} = Joken.decode(token, "secret") 
    assert(payload == decoded_payload) 
  end

  test "expiration" do
    payload = %{ sub: 1234567890, name: "John Doe", admin: true, exp: get_current_time() + 300 }
    {:ok, token} = Joken.encode(payload, "secret", :HS256, %{})
    {status, decoded_payload} = Joken.decode(token, "secret")
    assert(status == :ok) 

    payload = %{ sub: 1234567890, name: "John Doe", admin: true, exp: get_current_time() - 300 }
    {:ok, token} = Joken.encode(payload, "secret", :HS256, %{})
    {status, decoded_payload} = Joken.decode(token, "secret")
    assert(status == :error) 
  end

end
