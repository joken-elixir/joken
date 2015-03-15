# v0.10.0

* Enhancements
  * No longer has a dependency on Timex or JSX
  * Can now use any json library as long as you implement the behaviour, `Joken.Codec`
  * Joken module is now a GenServer
  * secret_key, algorithm, and json_module are now configured when the starting Joken module

* Breaking
  * `Joken.encode(payload, secret, algorithm, claims)` is now `Joken.encode(pid, payload, claims)` and `Joken.decode(token, secret, claims)` is now `Joken.decode(pid, token, claims)`. `secret_key` and `algorithm` are now configured along with `json_module` when starting the Joken module via any of the `Joken.start_link` functions. You could also use the `Joken.Token` module directly instead which isn't a GenServer and allows you to put in all of the parameters needed whenever you call encode or decode. 