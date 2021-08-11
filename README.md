# Joken

[![Build](https://travis-ci.org/joken-elixir/joken.svg?branch=master)](https://travis-ci.org/joken-elixir/joken)
[![Module Version](https://img.shields.io/hexpm/v/joken.svg)](https://hex.pm/packages/joken)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/joken/)
[![Total Download](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken)
[![License](https://img.shields.io/hexpm/l/joken.svg)](https://github.com/joken-elixir/joken/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/joken-elixir/joken.svg)](https://github.com/joken-elixir/joken/commits/master)

A JSON Web Token (JWT) Library.

Please, do read our comprehensive documentation and guides:

- [Changelog](https://hexdocs.pm/joken/changelog.html)
- [Joken Overview](https://hexdocs.pm/joken/introduction.html)
- [Configuration](https://hexdocs.pm/joken/configuration.html)
- [Signers](https://hexdocs.pm/joken/signer.html)
- [Asymmetric cryptography signers](https://hexdocs.pm/joken/assymetric_cryptography_signers.html)
- [Testing your app with Joken](https://hexdocs.pm/joken/testing.html)
- [JWT Common use cases](https://hexdocs.pm/joken/common_use_cases.html)
- [Migrating from Joken 1.0](https://hexdocs.pm/joken/migration_from_1.html)
- [Custom header arguments](https://hexdocs.pm/joken/custom_header_arguments.html)

## Usage

Add `:joken` to your list of dependencies in `mix.exs`:

``` elixir
def deps do
  # .. other deps
  {:joken, "~> 2.0"},
  # Recommended JSON library
  {:jason, "~> 1.1"}
end
```

All set! (don't forget to take a look at our comprehensive [documentation and guides](https://hexdocs.pm/joken/introduction.html)!)

## Benchmarking

Just run the benchmark script based on the supported algorithm:

``` shell
mix run benchmarks/hs_benchmark.exs
mix run benchmarks/jose_hs_benchmark.exs
mix run benchmarks/pem_rs_benchmark.exs
mix run benchmarks/rs_benchmark.exs
```

## License

Copyright (c) 2014 Bryan Joseph

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Disclaimer

This library would not be possible without the work of @potatosalad (Andrew Bennet). Specifically his library [erlang-jose](https://github.com/potatosalad/erlang-jose/).
