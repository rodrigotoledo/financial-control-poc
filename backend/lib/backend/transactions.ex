defmodule Backend.Transactions do
  import Ecto.Query
  alias Backend.Repo
  alias Backend.Accounts.Account
  alias Backend.Funds.Fund
  alias Backend.Funds.Investment
  alias Backend.Transactions.Transaction

  def process_transaction(account_id, type, amount, idempotency_key, opts \\ []) do
    after_account_update = Keyword.get(opts, :after_account_update, fn _account -> {:ok, nil} end)

    Repo.transaction(fn ->
      transaction = insert_transaction!(account_id, type, amount, idempotency_key)

      account =
        Account
        |> where([a], a.id == ^account_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      case validate_transaction(account, type, amount) do
        :ok ->
          updated_account = update_account_balance!(account, type, amount)

          case after_account_update.(updated_account) do
            {:ok, payload} ->
              %{account: updated_account, transaction: transaction, payload: payload}

            {:error, reason} ->
              Repo.rollback(reason)
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, result} ->
        {:ok, result}

      {:error, %Ecto.ConstraintError{constraint: "transactions_idempotency_key_index"}} ->
        {:error, :duplicate_request}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def invest_in_fund(account_id, fund_id, amount, idempotency_key) do
    process_transaction(account_id, "investment", amount, idempotency_key,
      after_account_update: fn account ->
        fund =
          Fund
          |> where([f], f.id == ^fund_id)
          |> lock("FOR UPDATE")
          |> Repo.one!()

        shares_count = Decimal.div(amount, fund.current_share_price)

        investment_params = %{
          user_id: account.user_id,
          fund_id: fund.id,
          shares_count: shares_count,
          invested_amount: amount
        }

        %Investment{}
        |> Investment.changeset(investment_params)
        |> Repo.insert()
      end
    )
  end

  defp validate_transaction(account, type, amount) do
    case type do
      "withdraw" ->
        if Decimal.compare(account.balance, amount) == :lt do
          {:error, :insufficient_funds}
        else
          :ok
        end

      "deposit" ->
        :ok

      "investment" ->
        if Decimal.compare(account.balance, amount) == :lt do
          {:error, :insufficient_funds}
        else
          :ok
        end

      _ ->
        {:error, :invalid_transaction_type}
    end
  end

  defp update_account_balance!(account, type, amount) do
    new_balance =
      case type do
        "deposit" -> Decimal.add(account.balance, amount)
        "withdraw" -> Decimal.sub(account.balance, amount)
        "investment" -> Decimal.sub(account.balance, amount)
      end

    account
    |> Account.changeset(%{balance: new_balance, version: account.version + 1})
    |> Repo.update!()
  end

  defp insert_transaction!(account_id, type, amount, idempotency_key) do
    transaction_params = %{
      account_id: account_id,
      type: type,
      amount: amount,
      idempotency_key: idempotency_key
    }

    case %Transaction{} |> Transaction.changeset(transaction_params) |> Repo.insert() do
      {:ok, transaction} ->
        transaction

      {:error, changeset} ->
        if idempotency_error?(changeset) do
          Repo.rollback(:duplicate_request)
        else
          Repo.rollback(changeset)
        end
    end
  end

  def get_transactions(account_id, limit \\ 10) do
    Transaction
    |> where([t], t.account_id == ^account_id)
    |> order_by([t], desc: t.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp idempotency_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:idempotency_key, {_message, opts}} -> opts[:constraint] == :unique
      _other -> false
    end)
  end
end
