defmodule BackendWeb.FundController do
  use BackendWeb, :controller
  import Ecto.Query
  alias Backend.Funds.Fund
  alias Backend.Repo
  alias Backend.Transactions

  def index(conn, _params) do
    funds = Fund |> order_by([f], asc: f.name) |> Repo.all()

    json(conn, %{funds: Enum.map(funds, &fund_json/1)})
  end

  def invest(conn, %{"id" => fund_id, "amount" => amount, "account_id" => account_id}) do
    with {:ok, idempotency_key} <- get_idempotency_key(conn),
         {:ok, decimal_amount} <- parse_amount(amount),
         {:ok, result} <-
           Transactions.invest_in_fund(account_id, fund_id, decimal_amount, idempotency_key) do
      investment = result.payload

      json(conn, %{
        account_balance: money(result.account.balance),
        investment: %{
          id: investment.id,
          fund_id: investment.fund_id,
          shares_count: money(investment.shares_count),
          invested_amount: money(investment.invested_amount)
        },
        status: "success"
      })
    else
      error -> render_error(conn, error)
    end
  end

  defp get_idempotency_key(conn) do
    case get_req_header(conn, "x-idempotency-key") do
      [key] when key != "" -> {:ok, key}
      _ -> {:error, :missing_idempotency_key}
    end
  end

  defp parse_amount(amount) when is_binary(amount) do
    case Decimal.parse(amount) do
      {decimal, ""} -> validate_positive_amount(decimal)
      _other -> {:error, :invalid_amount}
    end
  end

  defp parse_amount(amount) when is_integer(amount),
    do: validate_positive_amount(Decimal.new(amount))

  defp parse_amount(_amount), do: {:error, :invalid_amount}

  defp validate_positive_amount(amount) do
    if Decimal.compare(amount, Decimal.new(0)) == :gt do
      {:ok, amount}
    else
      {:error, :invalid_amount}
    end
  end

  defp render_error(conn, {:error, :duplicate_request}) do
    conn
    |> put_status(:conflict)
    |> json(%{error: "duplicate_request"})
  end

  defp render_error(conn, {:error, %Ecto.Changeset{}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_request"})
  end

  defp render_error(conn, {:error, reason}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: to_string(reason)})
  end

  defp fund_json(fund) do
    previous = fund.previous_share_price || fund.current_share_price

    %{
      id: fund.id,
      name: fund.name,
      current_share_price: money(fund.current_share_price),
      previous_share_price: money(previous),
      change_percent: money(change_percent(fund.current_share_price, previous))
    }
  end

  defp change_percent(current, previous) do
    if Decimal.compare(previous, Decimal.new(0)) == :eq do
      Decimal.new(0)
    else
      current
      |> Decimal.sub(previous)
      |> Decimal.div(previous)
      |> Decimal.mult(Decimal.new(100))
    end
  end

  defp money(decimal), do: Decimal.to_string(decimal, :normal)
end
