defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.User
  alias ExBanking.Balance
  alias ExBanking.Counter

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    User.create(user)
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:ok, new_balance :: number()}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount >= 0 and is_binary(currency) do
    with {:ok, user} <- User.get(user) do
      Counter.increment(user)

      Balance.deposit(user, amount, currency) |> decrement_counter(user)
    end
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    with {:ok, user} <- User.get(user) do
      Counter.increment(user)

      Balance.withdraw(user, amount, currency) |> decrement_counter(user)
    end
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    with {:ok, user} <- User.get(user) do
      Counter.increment(user)

      Balance.get_balance(user, currency) |> decrement_counter(user)
    end
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number(),
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number(), to_user_balance :: number()}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    with {:sender, {:ok, from_user}} <- {:sender, User.get(from_user)},
         {:receiver, {:ok, to_user}} <- {:receiver, User.get(to_user)} do
      Counter.increment(from_user)
      Counter.increment(to_user)

      Balance.send(from_user, to_user, amount, currency)
      |> decrement_counter(from_user)
      |> decrement_counter(to_user)
    else
      {:sender, {:error, _message}} ->
        {:error, :sender_does_not_exist}

      {:receiver, {:error, _message}} ->
        {:error, :receiver_does_not_exist}

      error ->
        error
    end
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}

  defp decrement_counter(result, user) do
    Counter.decrement(user)

    result
  end
end
