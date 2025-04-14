import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :landbuyer, Landbuyer.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "landbuyer.fly.dev"
  port = 8080

  config :landbuyer, LandbuyerWeb.Endpoint,
    server: true,  # ✅ FORCÉ ici, plus besoin de PHX_SERVER
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    cache_static_manifest: "priv/static/cache_manifest.json",
    check_origin: ["https://landbuyer.fly.dev"]

  config :landbuyer,
    username: System.fetch_env!("ADMIN_USERNAME"),
    password: System.fetch_env!("ADMIN_PASSWORD")
end
