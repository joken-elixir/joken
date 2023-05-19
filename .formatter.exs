# Used by "mix format"
[
  locals_without_parens: [add_hook: 1, add_hook: 2],
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 100,
  plugins: [Styler]
]
