alias Backend.Accounts.{Account, User}
alias Backend.Funds.Fund
alias Backend.Repo

funds = [
  %{name: "Atlas Growth", current_share_price: "125.5000", previous_share_price: "125.5000"},
  %{name: "Income Harbor", current_share_price: "98.7500", previous_share_price: "98.7500"},
  %{name: "Tech Horizon", current_share_price: "215.3000", previous_share_price: "215.3000"},
  %{name: "Green Yield", current_share_price: "74.4200", previous_share_price: "74.4200"}
]

Enum.each(funds, fn attrs ->
  case Repo.get_by(Fund, name: attrs.name) do
    nil -> %Fund{} |> Fund.changeset(attrs) |> Repo.insert!()
    fund -> fund |> Fund.changeset(attrs) |> Repo.update!()
  end
end)

user =
  case Repo.get_by(User, email: "demo@financial-control.local") do
    nil ->
      %User{}
      |> User.changeset(%{
        email: "demo@financial-control.local",
        password: "demo-password"
      })
      |> Repo.insert!()

    user ->
      user
  end

case Repo.get_by(Account, user_id: user.id) do
  nil ->
    %Account{}
    |> Account.changeset(%{user_id: user.id, balance: "1250.50", version: 0})
    |> Repo.insert!()

  account ->
    account
end
