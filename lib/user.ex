defmodule ExBanking.User do
  use GenServer

  def start_link(default_opts) when is_list(default_opts) do
    GenServer.start_link(__MODULE__, default_opts, name: __MODULE__)
  end

  def create(user) do
    GenServer.call(__MODULE__, {:create, user})
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
      {:reply, :ok, [user | users]}
    end
  end
end
