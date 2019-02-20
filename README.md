# Joken

[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/joken/) [![Downloads](https://img.shields.io/hexpm/dt/joken.svg)](https://hex.pm/packages/joken) [![Build](https://travis-ci.org/joken-elixir/joken.svg?branch=master)](https://travis-ci.org/joken-elixir/joken)

[Documentation](http://hexdocs.pm/joken/)

A JSON Web Token (JWT) Library

Please, see our documentation and guides [here](http://hexdocs.pm/joken/)

## Usage

Add Joken to your deps:

``` elixir
def deps do
  # .. other deps
  {:joken, "~> 2.0"},
  # Recommended JSON library
  {:jason, "~> 1.1"}
end
```

All set! (don't forget to take a look at our guides and documentation!)

## Benchmarking

To run benchmarks just:

``` shell
# mix run benchmarks/{some_benchmark_file}.exs

# Example:
mix run benchmarks/hs_benchmark.exs
```

## LICENSE

See the [LICENSE.txt](LICENSE.txt) file.

## DISCLAIMER

This library would not be possible without the work of @potatosalad (Andrew Bennet). Specifically his library [erlang-jose](https://github.com/potatosalad/erlang-jose/)
