defmodule BackendWeb.FundControllerTest do
  use BackendWeb.ConnCase
  alias Backend.Repo
  alias Backend.Accounts.{User, Account}
  alias Backend.Funds.Fund

  setup do
    user =
      %User{}
      |> User.changeset(%{email: "investor@example.com", password: "test123"})
      |> Repo.insert!()

    account =
      %Account{}
      |> Account.changeset(%{user_id: user.id, balance: Decimal.new("5000.00")})
      |> Repo.insert!()

    fund =
      %Fund{}
      |> Fund.changeset(%{name: "Test Fund", current_share_price: Decimal.new("100.0000")})
      |> Repo.insert!()

    {:ok, account: account, user: user, fund: fund}
  end

  describe "GET /api/funds" do
    test "lists all funds with current prices", %{fund: fund, conn: conn} do
      conn = get(conn, "/api/funds")

      response = json_response(conn, 200)
      assert is_list(response["funds"])
      assert length(response["funds"]) > 0

      fund_data = Enum.find(response["funds"], &(&1["id"] == fund.id))
      assert fund_data["name"] == "Test Fund"
      assert fund_data["current_share_price"] == "100.0000"
    end
  end

  describe "POST /api/funds/:id/invest" do
    test "successful investment deducts from account and creates shares", %{
      account: account,
      fund: fund,
      conn: conn
    } do
      idempotency_key = "test-invest-#{System.unique_integer()}"

      conn =
        post(conn, "/api/funds/#{fund.id}/invest", %{
          "amount" => "500.00",
          "account_id" => account.id
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      response = json_response(conn, 200)
      assert response["status"] == "success"
      # Balance reduced by investment amount
      assert response["account_balance"] == "4500.00"
      # Shares = 500 / 100 = 5
      assert response["investment"]["shares_count"] == "5.0000"
      assert response["investment"]["invested_amount"] == "500.00"
    end

    test "insufficient funds returns 400", %{account: account, fund: fund, conn: conn} do
      idempotency_key = "test-invest-fail-#{System.unique_integer()}"

      conn =
        post(conn, "/api/funds/#{fund.id}/invest", %{
          "amount" => "10000.00",
          "account_id" => account.id
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn, 400)["error"] =~ "insufficient_funds"
    end

    test "duplicate investment idempotency key returns 409", %{
      account: account,
      fund: fund,
      conn: conn
    } do
      idempotency_key = "test-invest-dup-#{System.unique_integer()}"

      # First investment
      conn1 =
        post(conn, "/api/funds/#{fund.id}/invest", %{
          "amount" => "100.00",
          "account_id" => account.id
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn1, 200)["status"] == "success"

      # Duplicate with same key
      conn2 =
        post(conn, "/api/funds/#{fund.id}/invest", %{
          "amount" => "100.00",
          "account_id" => account.id
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn2, 409)["error"] == "duplicate_request"
    end

    test "missing idempotency key returns 400", %{account: account, fund: fund, conn: conn} do
      conn =
        post(conn, "/api/funds/#{fund.id}/invest", %{
          "amount" => "100.00",
          "account_id" => account.id
        })

      assert json_response(conn, 400)["error"] =~ "missing_idempotency_key"
    end
  end
end
