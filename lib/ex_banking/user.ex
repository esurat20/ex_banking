defmodule ExBanking.User do
  use GenServer

  def start_link(default_opts) when is_list(default_opts) do
    GenServer.start_link(__MODULE__, default_opts, name: __MODULE__)
  end

  def create(user) do
    GenServer.call(__MODULE__, {:create, user})
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  # Callbacks

  @impl true
  def init(value) do
    {:ok, value}
  end

  @impl true
  def handle_call({:create, user}, _from, users) do
    if Enum.any?(users, &(&1 == user)) do
      {:reply, {:error, :user_already_exists}, users}
    else
      with {:ok, _pid} <- ExBanking.Balance.start_link(user),
           {:ok, _pid} <- ExBanking.Counter.start_link(user) do
        {:reply, :ok, [user | users]}
      end
    end
  end

  @impl true
  def handle_call({:get, name}, _from, users) do
    {:reply, find_user(users, name), users}
  end

  defp find_user(users, name) do
    case Enum.find(users, &(&1 == name)) do
      nil ->
        {:error, :user_does_not_exist}

      user ->
        {:ok, user}
    end
  end
end
