Joken
=====

Encodes and decodes JSON Web Tokens.

Currently supports the following algorithms:

* HS256
* HS384
* HS512

Currently validates the following:

* Signature
* Expiration (exp)
* Not Before (nbf)
* Audience (aud)
* Issuer (iss)
* Subject (sub)

```
    iex(1)> Joken.encode(%{username: "johndoe"}, "secret")
    {:ok,
     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog"}
    iex(2)> Joken.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog", "secret")
    {:ok, %{username: "johndoe"}}

    iex(3)> Joken.encode(%{username: "johndoe"}, "secret", :HS384, %{ iss: "self"})                                                                                                                  {:ok,
     "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1"}
    iex(4)> Joken.decode("eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzZWxmIiwidXNlcm5hbWUiOiJqb2huZG9lIn0.wG_LAQ7Z3uRl7B0TEuxvfHdqikU3boPorm5ldS6dutJ9r076i-LRCuascaxoNDw1", "secret", %{ iss: "not:self"})
    {:error, "Invalid issuer"}
```
