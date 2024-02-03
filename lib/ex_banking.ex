defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.User
  alias ExBanking.Balance
  alias ExBanking.Currency

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    User.create(user)
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  # @spec deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
  #         {:ok, new_balance :: number()}
  #         | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  # def deposit(user, amount, currency) do
  #   with {:ok, user} <- User.get(user),
  #        {:ok, currency} <- Currency.get_or_create(currency) do
  #     Balance.deposit(user, amount, currency)
  #   end
  # end
end
