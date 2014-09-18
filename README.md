Joken
=====

Encodes and decodes JSON Web Tokens.

```
iex(1)> Joken.encode(%{username: "johndoe"}, "secret", :HS256, %{})
{:ok,
 "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog"}
iex(2)> Joken.decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImpvaG5kb2UifQ.OFY_3SbHl2YaM7Y4Lj24eVMtcDaGEZU7KRzYCV4cqog")
{:ok, %{username: "johndoe"}}
```
