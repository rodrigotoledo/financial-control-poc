defmodule BackendWeb.AccountController do
  use BackendWeb, :controller
  alias Backend.Accounts.Account
  alias Backend.Repo
  alias Backend.Transactions

  def show(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)
    recent_transactions = Transactions.get_transactions(id, 10)

    json(conn, %{
      id: account.id,
      user_id: account.user_id,
      balance: money(account.balance),
      transactions: Enum.map(recent_transactions, &transaction_json/1)
    })
  end

  def deposit(conn, %{"id" => id, "amount" => amount}) do
    with {:ok, idempotency_key} <- get_idempotency_key(conn),
         {:ok, decimal_amount} <- parse_amount(amount),
         {:ok, result} <-
           Transactions.process_transaction(id, "deposit", decimal_amount, idempotency_key) do
      json(conn, %{balance: money(result.account.balance), status: "success"})
    else
      error -> render_error(conn, error)
    end
  end

  def withdraw(conn, %{"id" => id, "amount" => amount}) do
    with {:ok, idempotency_key} <- get_idempotency_key(conn),
         {:ok, decimal_amount} <- parse_amount(amount),
         {:ok, result} <-
           Transactions.process_transaction(id, "withdraw", decimal_amount, idempotency_key) do
      json(conn, %{balance: money(result.account.balance), status: "success"})
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

  defp transaction_json(transaction) do
    %{
      id: transaction.id,
      type: transaction.type,
      amount: money(transaction.amount),
      idempotency_key: transaction.idempotency_key,
      inserted_at: transaction.inserted_at
    }
  end

  defp money(decimal), do: Decimal.to_string(decimal, :normal)
end
