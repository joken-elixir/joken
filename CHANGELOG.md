## v1.3.1

* Enhancements
  - Updates Elixir requirement to 1.2.3 (thanks to [@supernintendo](https://github.com/supernintendo))

## v1.3.0

* Enhancements
    - Update jose dependency to 1.8
    - Now requires Elixir 1.2 or greater
    - Remove debug logging statements (thanks to [@MSch](https://github.com/MSch))

## v1.2.2

* Bug fixes
    - Fix incorrect property name in `with_header_args/2` (thanks to [@hogjosh](https://github.com/hogjosh))
    - Extend 'with_validation' to accept a custom message (thanks to [@IamfromSpace](https://github.com/IamfromSpace))
    - Fix typos in README.md (thanks to [@ugisozols](https://github.com/ugisozols))
    - Fix warnings introduced in Elixir 1.3

## v1.2.1

* Bug Fixes
    - with_validation - Fixed an issue where validations were automatically passed if the validation key was not in the payload

## v1.2.0

* Enhancements
    - Bumped JOSE dependency to 1.7.3 adding native `libsodium`, `keccakf1600` and `libdecaf` support. Documentation updated to account for that.
    - Generated claims are available after signing (thanks to [@lnikkila](https://github.com/lnikkila))
    - Using `credo` lint checker

* Bug fixes
    - Fix validation of `iat` on the same second (thanks to [@lnikkila](https://github.com/lnikkila))
    - Fix using `@on_load` to better support [`exrm`](https://github.com/bitwalker/exrm) (thanks to [@tonyarkles](https://github.com/tonyarkles))

* Deprecations:
    - `Joken.Plug`: `on_verifying` option has been replaced by `verify`. The private option, `joken_on_verifying` has been replaced with `joken_verify` as well.
      `on_verifying` and `joken_on_verifying` will be removed in a future version.
    - Configuration of `none` algorithm is no longer done automatically. To allow the `none` algorithm, set `allow_none_algorithm` as before and call `Joken.Signer.configure_unsecured_signing()` once during your application's start

## v1.1.1

* Bug Fixes
    - with_validation - Fixed an issue where validations were automatically passed if the validation key was not in the payload

## v1.1.0

* Enhancements
    - Add EdDSA support: Ed25519, Ed25519ph, Ed448, Ed448ph

## v1.0.1

* Bug Fixes
    * with_validation - Fixed an issue where validations were automatically passed if the validation key was not in the payload

## v1.0.0

* Enhancements
    * The `none` algorithm can be used if and only if `allow_none_algorithm` exists as an application variable on the `joken` app and is set to `true`. Otherwise an error is thrown

    * Joken: added `peek/2`, `get_data/1`, `with_header_arg/3`, `with_header_args/2`, `none/1`

* Bug fixes
    * Ensures `Plug` is loading before loading `Joken.Plug`

## v0.16.1

* Bug Fixes
    * `Joken.Plug` - Fixed capture of default `on_error` function causing compilation errors

## v0.16.0

* Enhancements
    * Updated API to allow for more flexibility for signing and verifying tokens
    * Joken.Plug has been added.
    * Small fixes to make sure Joken works with Elixir 1.1
    * Added support for the following signing algorithms:
        * ES256
        * ES384
        * ES512
        * PS256
        * PS384
        * PS512
        * RS256
        * RS384
        * RS512

* Breaking
    * The new API is completely different than the old one. Take a look [here to find out how to go from 0.15 to 0.16](https://github.com/bryanjos/joken/wiki/Moving-from-0.15-to-0.16)
    * `encode` and `decode` in the Joken module have been renamed to `sign` and `verify`.
    * This release also deprecates [plugJWT](https://hex.pm/packages/plug_jwt). Use `Joken.Plug` instead

## v0.15.0

* Enhancements
    * Add options parameter to `Joken.Config.validate_claim`
    * Moved validation helpers functions to `Joken.Helpers`

## v0.14.1

* Enhancements
    * Using the Dict Protocol for accessing data

## v0.14.0

* Enhancements
    * The `Joken.Config` behaviour handles the configuration of the secret_key, algorithm, encode and decode functions, as well as functions for adding and validating claims
    * Add `options` parameter to `Joken.Token.decode`
    * Add `options` parameter to `Joken.decode`
    * Removed `:none` algorithm completely

* Breaking
    * `Joken.Codec` is replaced by `Joken.Config`.
    * `json_module` in config is replaced by `config_module`.
    * `algorithm` and `secret_key` in config is replaced by implementing the `algorithm` and `secret_key` functions on `Joken.Config`.
    * `Joken.Token.encode` now has a signature of `(joken_config, payload)` since the algorithm and secret key are defined inside of the passed in `joken_config` module.
    * `Joken.Token.decode` now has a signature of `(joken_config, jwt, options \\ [])` since the algorithm and secret key are defined inside of the passed in `joken_config` module.

## v0.13.1

* Enhancements
    * Checking to make sure signature is on token unless `:none` is passed as the algorithm

## v0.13.0

* Enhancements
    * Validating iat claim
    * Verifying signature before getting the data
p
## v0.12.0

* Enhancements
    * Signature is now verified just from the header and payload strings.
    * Added `decode_secret_key?` parameter

## v0.11.0

* Enhancements
    * `Joken` module now looks more like old API from 0.8 with the exception that it reads configuration from a :joken config block.
    * For security reasons, now using the configured algorithm for checking signature instead of the one specified in the header.
    * Added algorithm paramter to `Joken.Token.decode` to be used when verifying signatures

## v0.10.1

* Enhancements
    * Fixed documentation typos
    * Joken now uses an Agent instead of implementing GenServer


## v0.10.0

* Enhancements
    * No longer has a dependency on Timex or JSX
    * Can now use any json library as long as you implement the behaviour, `Joken.Codec`
    * Joken module is now a GenServer
    * secret_key, algorithm, and json_module are now configured when the starting Joken module

* Breaking
    * `Joken.encode(payload, secret, algorithm, claims)` is now `Joken.encode(pid, payload, claims)` and `Joken.decode(token, secret, claims)` is now `Joken.decode(pid, token, claims)`. `secret_key` and `algorithm` are now configured along with `json_module` when starting the Joken module via any of the `Joken.start_link` functions. You could also use the `Joken.Token` module directly instead which isn't a GenServer and allows you to put in all of the parameters needed whenever you call encode or decode.
