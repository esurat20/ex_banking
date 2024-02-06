defmodule ExBanking.Counter do
  use Agent

  def start_link(user) do
    Agent.start_link(fn -> 0 end, name: via_name(user))
  end

  def value(user) do
    user
    |> via_name()
    |> Agent.get(& &1)
  end

  def increment(user) do
    user
    |> via_name()
    |> Agent.update(&(&1 + 1))
  end

  def decrement(user) do
    user
    |> via_name()
    |> Agent.update(&(&1 - 1))
  end

  defp via_name(user) do
    {:via, Registry, {Registry.CounterNames, user}}
  end
end
