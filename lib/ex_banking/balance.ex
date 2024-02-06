defmodule ExBanking.Balance do
  use GenServer

  alias ExBanking.Currenncy
  alias ExBanking.Counter

  def start_link(user) do
    name = via_name(user)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def deposit(user, amount, currency) do
    if Counter.value(user) <= 10 do
      user
      |> via_name()
      |> GenServer.call({:deposit, amount, currency})
    else
      {:error, :too_many_requests_to_user}
    end
  end

  def withdraw(user, amount, currency) do
    if Counter.value(user) <= 10 do
      user
      |> via_name()
      |> GenServer.call({:withdraw, amount, currency})
    else
      {:error, :too_many_requests_to_user}
    end
  end

  def get_balance(user, currency) do
    if Counter.value(user) <= 10 do
      user
      |> via_name()
      |> GenServer.call({:get_balance, currency})
    else
      {:error, :too_many_requests_to_user}
    end
  end

  def send(from_user, to_user, amount, currency) do
    with {:sender_count, count} when count <= 10 <- {:sender_count, Counter.value(from_user)},
         {:receiver_count, count} when count <= 10 <- {:receiver_count, Counter.value(to_user)},
         {:ok, sender_amount} <- withdraw(from_user, amount, currency),
         {:ok, receiver_amount} <- deposit(to_user, amount, currency) do
      {:ok, sender_amount, receiver_amount}
    else
      {:sender_count, _count} ->
        {:error, :too_many_requests_to_sender}

      {:receiver_count, _count} ->
        {:error, :too_many_requests_to_receiver}

      error ->
        error
    end
  end

  # Callbacks

  @impl true
  def init(attrs) do
    {:ok, attrs}
  end

  @impl true
  def handle_call({:deposit, amount, currency}, _from, balances) do
    case Enum.split_with(balances, &(elem(&1, 0) == currency)) do
      {[{currency, current_amount}], balances} ->
        new_amount = Float.round(current_amount + amount, 2)

        {:reply, {:ok, new_amount}, [{currency, new_amount} | balances]}

      {[], balances} ->
        :ok = Currenncy.create(currency)
        amount = prepare_amount(amount)

        {:reply, {:ok, amount}, [{currency, amount} | balances]}
    end
  end

  @impl true
  def handle_call({:withdraw, amount, currency}, _from, init_balances) do
    case Enum.split_with(init_balances, &(elem(&1, 0) == currency)) do
      {[{currency, current_amount}], balances} ->
        if current_amount >= amount do
          new_amount = Float.round(current_amount - amount, 2)
          {:reply, {:ok, new_amount}, [{currency, new_amount} | balances]}
        else
          {:reply, {:error, :not_enough_money}, init_balances}
        end

      {[], balances} ->
        {:reply, {:error, :not_enough_money}, balances}
    end
  end

  @impl true
  def handle_call({:get_balance, currency}, _from, balances) do
    case Enum.find(balances, &(elem(&1, 0) == currency)) do
      nil ->
        {:reply, {:ok, 0.0}, balances}

      {_currency, current_balance} ->
        {:reply, {:ok, current_balance}, balances}
    end
  end

  defp via_name(user) do
    {:via, Registry, {Registry.UserNames, user}}
  end

  defp prepare_amount(amount) when is_float(amount), do: Float.round(amount, 2)

  defp prepare_amount(amount) when is_integer(amount), do: Float.round(amount * 1.0, 2)
end
