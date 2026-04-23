defmodule Backend.Funds.PriceUpdater do
  use GenServer
  alias Backend.Repo
  alias Backend.Funds.Fund

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule_update()
    {:ok, :ok}
  end

  @impl true
  def handle_info(:update_prices, state) do
    update_all_prices()
    schedule_update()
    {:noreply, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update_prices, 5000)
  end

  defp update_all_prices do
    Fund
    |> Repo.all()
    |> Enum.each(&update_fund_price/1)
  end

  defp update_fund_price(fund) do
    variation = random_variation()
    new_price = fund.current_share_price |> Decimal.add(variation) |> floor_price()

    fund
    |> Fund.changeset(%{
      current_share_price: new_price,
      previous_share_price: fund.current_share_price
    })
    |> Repo.update()
  end

  defp floor_price(price) do
    minimum = Decimal.new("0.0100")

    if Decimal.compare(price, minimum) == :lt do
      minimum
    else
      price
    end
  end

  defp random_variation do
    Decimal.new(:rand.uniform(101) - 51)
    |> Decimal.div(Decimal.new(1000))
  end
end
