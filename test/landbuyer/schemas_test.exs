defmodule Landbuyer.SchemasTest do
  use Landbuyer.DataCase, async: true

  alias Landbuyer.Accounts

  describe "Basic CRUD" do
    @account %{
      "label" => "label",
      "oanda_id" => "oanda_id",
      "hostname" => "hostname",
      "token" => "token"
    }

    @trader %{
      "state" => :paused,
      "strategy" => :empty,
      "rate_ms" => 1000,
      "instrument" => %{
        "currency_pair" => "XXX_YYY",
        "round_decimal" => 4
      },
      "options" => %{
        "distance_on_take_profit" => 10,
        "distance_between_position" => 1,
        "distance_on_stop_loss" => 20,
        "position_amount" => 20,
        "max_order" => 10
      }
    }

    test "Create account" do
      assert {:ok, _} = Accounts.create(@account)
    end

    test "Update account" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, account} = Accounts.update(account, %{"label" => "Instance de test 2"})

      assert account.label == "Instance de test 2"
    end

    test "Delete account" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, _} = Accounts.delete(account)

      assert {:error, :not_found} = Accounts.get(account.id)
    end

    test "Create trader" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, _} = Accounts.create_trader(account, @trader)
    end

    test "Update trader" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, trader} = Accounts.create_trader(account, @trader)
      assert {:ok, trader} = Accounts.update_trader(trader, %{"state" => "active"})

      assert trader.state == :active
    end

    test "Delete trader" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, trader} = Accounts.create_trader(account, @trader)
      assert {:ok, _} = Accounts.delete_trader(trader)

      assert {:ok, account} = Accounts.get(account.id)
      assert account.traders == []
    end

    test "Get account" do
      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, _} = Accounts.create_trader(account, @trader)

      assert {:ok, account} = Accounts.get(account.id)
      assert account.traders != nil
    end

    test "Get all accounts" do
      assert {:ok, _} = Accounts.create(@account)
      assert {:ok, _} = Accounts.create(@account)
      assert {:ok, _} = Accounts.create(@account)

      assert length(Accounts.get_all()) == 3
    end

    test "Operations on events" do
      event1 = %{type: :error, reason: "nothing", message: %{data1: "data1", data2: "data2"}}
      event2 = %{type: :success, reason: "stuff", message: %{}}
      event3 = %{type: :success, reason: "stuff", message: %{data1: "data1", data2: "data2"}}

      assert {:ok, account} = Accounts.create(@account)
      assert {:ok, trader} = Accounts.create_trader(account, @trader)

      assert {:ok, %Landbuyer.Schemas.Event{}} = Accounts.create_event(trader, event1)
      assert {:ok, %Landbuyer.Schemas.Event{}} = Accounts.create_event(trader, event2)
      assert {:ok, %Landbuyer.Schemas.Event{}} = Accounts.create_event(trader, event3)

      # Test get_last_events
      events = Accounts.get_last_events(trader)
      assert length(events) == 3

      # Test get_last_events of type :success
      events = Accounts.get_last_events(trader, [:success])
      assert length(events) == 2

      # Test get_last_events with limit
      events = Accounts.get_last_events(trader, :all, 1)
      assert length(events) == 1
    end
  end
end
