defmodule BackendWeb.AccountControllerTest do
  use BackendWeb.ConnCase
  alias Backend.Repo
  alias Backend.Accounts.{User, Account}

  setup do
    user =
      %User{}
      |> User.changeset(%{email: "test@example.com", password: "test123"})
      |> Repo.insert!()

    account =
      %Account{}
      |> Account.changeset(%{user_id: user.id, balance: Decimal.new("1000.00")})
      |> Repo.insert!()

    {:ok, account: account, user: user}
  end

  describe "POST /api/accounts/:id/withdraw" do
    test "successful withdrawal with idempotency key", %{account: account, conn: conn} do
      idempotency_key = "test-withdraw-#{System.unique_integer()}"

      conn =
        post(conn, "/api/accounts/#{account.id}/withdraw", %{
          "amount" => "100.00"
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn, 200)["status"] == "success"
      assert json_response(conn, 200)["balance"] == "900.00"
    end

    test "duplicate idempotency key returns 409", %{account: account, conn: conn} do
      idempotency_key = "test-dup-#{System.unique_integer()}"

      # First request
      conn1 =
        post(conn, "/api/accounts/#{account.id}/withdraw", %{
          "amount" => "100.00"
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn1, 200)["status"] == "success"

      # Second request with same key
      conn2 =
        post(conn, "/api/accounts/#{account.id}/withdraw", %{
          "amount" => "100.00"
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn2, 409)["error"] == "duplicate_request"
    end

    test "missing idempotency key returns 400", %{account: account, conn: conn} do
      conn =
        post(conn, "/api/accounts/#{account.id}/withdraw", %{
          "amount" => "100.00"
        })

      assert json_response(conn, 400)["error"] =~ "missing_idempotency_key"
    end

    test "insufficient funds returns 400", %{account: account, conn: conn} do
      idempotency_key = "test-insuf-#{System.unique_integer()}"

      conn =
        post(conn, "/api/accounts/#{account.id}/withdraw", %{
          "amount" => "2000.00"
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn, 400)["error"] =~ "insufficient_funds"
    end
  end

  describe "POST /api/accounts/:id/deposit" do
    test "successful deposit increases balance", %{account: account, conn: conn} do
      idempotency_key = "test-deposit-#{System.unique_integer()}"

      conn =
        post(conn, "/api/accounts/#{account.id}/deposit", %{
          "amount" => "500.00"
        })
        |> put_req_header("x-idempotency-key", idempotency_key)

      assert json_response(conn, 200)["status"] == "success"
      assert json_response(conn, 200)["balance"] == "1500.00"
    end
  end

  describe "GET /api/accounts/:id" do
    test "returns account with recent transactions", %{account: account, conn: conn} do
      conn = get(conn, "/api/accounts/#{account.id}")

      response = json_response(conn, 200)
      assert response["balance"] == "1000.00"
      assert response["id"] == account.id
      assert is_list(response["transactions"])
    end
  end
end
