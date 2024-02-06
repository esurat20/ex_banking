defmodule ExBanking.Currenncy do
  use GenServer

  def start_link(default_opts) when is_list(default_opts) do
    GenServer.start_link(__MODULE__, default_opts, name: __MODULE__)
  end

  def create(currency) do
    GenServer.cast(__MODULE__, {:create, currency})
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  def exist?(currency) do
    GenServer.call(__MODULE__, {:exists?, currency})
  end

  # Callbacks

  @impl true
  def init(value) do
    {:ok, value}
  end

  @impl true
  def handle_cast({:create, currency}, currencies) do
    if exists?(currency, currencies) do
      {:noreply, currencies}
    else
      {:noreply, [currency | currencies]}
    end
  end

  @impl true
  def handle_call(:list, _from, currencies) do
    {:reply, currencies, currencies}
  end

  @impl true
  def handle_call({:exists?, currency}, _from, currencies) do
    {:reply, exists?(currency, currencies), currencies}
  end

  defp exists?(target_currency, currencies) do
    Enum.any?(currencies, &(&1 == target_currency))
  end
end
