# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Landbuyer.Repo.insert!(%Landbuyer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Insert an account
# account = %{
#   "label" => "Instance de test",
#   "oanda_id" => "101-001-756041-001",
#   "hostname" => "api-fxpractice.oanda.com",
#   "token" => "6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c"
# }

# {:ok, account} = Landbuyer.Accounts.create(account)

# # Insert a trader
# trader = %{
#   "state" => :paused,
#   "strategy" => :default,
#   "rate_ms" => 1000,
#   "instrument" => %{
#     "currency_pair" => "USD_CHF",
#     "round_decimal" => 4
#   },
#   "options" => %{
#     "distance_on_take_profit" => 0.0010,
#     "distance_between_position" => 0.01,
#     "distance_on_stop_loss" => 0.0,
#     "position_amount" => 20,
#     "max_order" => 10
#   }
# }

# {:ok, _trader} = Landbuyer.Accounts.create_trader(account, trader)

# account = %{
#   "label" => "Dummy account 1",
#   "oanda_id" => "101-001-756041-001",
#   "hostname" => "api-fxpractice.oanda.com",
#   "token" => "6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c"
# }

# {:ok, _account} = Landbuyer.Accounts.create(account)

# account = %{
#   "label" => "Dummy account 2",
#   "oanda_id" => "101-001-756041-001",
#   "hostname" => "api-fxpractice.oanda.com",
#   "token" => "6494b832545a92eb440d455e03ce1eac-1263e2633790a0c211a56bd21632409c"
# }

# {:ok, _account} = Landbuyer.Accounts.create(account)
