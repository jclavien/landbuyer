# Used by "mix format"
[
  plugins: [Styler, Phoenix.LiveView.HTMLFormatter],
  import_deps: [:ecto],
  inputs: [
    "*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "priv/*/seeds/*.exs",
    "{config,lib,test}/**/*.{heex,ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 118,
  heex_line_length: 128
]
