# Landbuyer App

Welcome to the Landbuyer App documentation!

TODO

# About the Project

TODO

## Features

TODO

# Installation

This project uses [Elixir](https://elixir-lang.org/) and the [web framework Phoenix/LiveView](https://www.phoenixframework.org/).

## Minimal Setup

To get started, follow these steps:

- Install dependencies with `mix deps.get`.
- Create and migrate your database with `mix ecto.setup`. Make sure you have PostgreSQL installed and configured. Default configuration for the development environment can be found in `config/dev.exs`.
- Start the Phoenix endpoint with `mix phx.server` or within IEx using `iex -S mix phx.server`.

You can access the app by visiting [`localhost:4000`](http://localhost:4000) in your browser.

## Accessing the App

During development, the admin username is `admin`, and the admin password is `1234`. You can modify these credentials in the `config/dev.exs` file as shown below:
``` elixir
# User and password for admin auth
config :landbuyer,
  username: "admin",
  password: "1234"
```

# Production

If you intend to deploy the app, please refer to the [official Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

However, the app is already configured for fast deployment on [fly.io](https://fly.io/). An example `fly.toml` configuration file can be found.

## Admin Panel Access in Production

During deployment, you'll need to set environment variables to access the admin panel. Here's an example of how to do it for fly.io:
``` bash
fly secrets set ADMIN_USERNAME={some_user}
fly secrets set ADMIN_PASSWORD={some_password}
```
