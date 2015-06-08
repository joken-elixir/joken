# v0.14.0-dev

* Enhancements
  * Can now control how claims are added as well as validated by overriding functions in `Joken.Parameters`
  * Add `skip` parameter to `Joken.Token.decode`

* Breaking
  * `Joken.Codec` is replaced by `Joken.Parameters`. 
  * `json_module` in config is replaced by `parameters_module`. 

# v0.13.0

* Enhancements
  * Validating iat claim
  * Verifying signature before getting the data

# v0.12.0

* Enhancements
  * Signature is now verified just from the header and payload strings.
  * Added `decode_secret_key?` parameter

# v0.11.0

* Enhancements
  * `Joken` module now looks more like old API from 0.8 with the exception that it reads configuration from a :joken config block.
  * For security reasons, now using the configured algorithm for checking signature instead of the one specified in the header.
  * Added algorithm paramter to `Joken.Token.decode` to be used when verifying signatures

# v0.10.1

* Enhancements
  * Fixed documentation typos
  * Joken now uses an Agent instead of implementing GenServer


# v0.10.0

* Enhancements
  * No longer has a dependency on Timex or JSX
  * Can now use any json library as long as you implement the behaviour, `Joken.Codec`
  * Joken module is now a GenServer
  * secret_key, algorithm, and json_module are now configured when the starting Joken module

* Breaking
  * `Joken.encode(payload, secret, algorithm, claims)` is now `Joken.encode(pid, payload, claims)` and `Joken.decode(token, secret, claims)` is now `Joken.decode(pid, token, claims)`. `secret_key` and `algorithm` are now configured along with `json_module` when starting the Joken module via any of the `Joken.start_link` functions. You could also use the `Joken.Token` module directly instead which isn't a GenServer and allows you to put in all of the parameters needed whenever you call encode or decode. 