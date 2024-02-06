defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  describe "create_user/1" do
    test "run" do
      assert :ok == ExBanking.create_user("Denys")
    end

    test "run with wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.create_user(nil)
    end

    test "run for already existed user" do
      ExBanking.User.start_link([])
      ExBanking.create_user("Bigman")

      assert {:error, :user_already_exists} == ExBanking.create_user("Bigman")
    end
  end

  describe "deposit/3" do
    test "run" do
      ExBanking.create_user("Ben")
      assert {:ok, 10.0} == ExBanking.deposit("Ben", 10, "USD")
    end

    test "run with float amount" do
      ExBanking.create_user("John")
      assert {:ok, 10.10} == ExBanking.deposit("John", 10.10, "USD")
    end

    test "run with 2 precision for amount" do
      ExBanking.create_user("Maria")
      assert {:ok, 10.26} == ExBanking.deposit("Maria", 10.255512, "USD")
    end

    test "run with wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.deposit(nil, nil, nil)
    end

    test "run with not existing user" do
      assert {:error, :user_does_not_exist} == ExBanking.deposit("Mike", 20, "USD")
    end

    test "run with request limit" do
      ExBanking.create_user("Limitted_deposit_user")
      Enum.each(1..10, fn _ -> ExBanking.Counter.increment("Limitted_deposit_user") end)

      assert {:error, :too_many_requests_to_user} ==
               ExBanking.deposit("Limitted_deposit_user", 50, "USD")
    end
  end

  describe "withdraw/3" do
    test "run" do
      ExBanking.create_user("Ron")
      ExBanking.deposit("Ron", 10, "USD")

      assert {:ok, 5.0} == ExBanking.withdraw("Ron", 5, "USD")
    end

    test "run with float amount" do
      ExBanking.create_user("Cher")
      ExBanking.deposit("Cher", 10, "USD")

      assert {:ok, 4.85} == ExBanking.withdraw("Cher", 5.15, "USD")
    end

    test "run with 2 precision for amount" do
      ExBanking.create_user("Can")
      ExBanking.deposit("Can", 10, "USD")

      assert {:ok, 4.8} == ExBanking.withdraw("Can", 5.2012, "USD")
    end

    test "run with not enough money" do
      ExBanking.create_user("Mall")
      ExBanking.deposit("Mall", 10, "USD")

      assert {:error, :not_enough_money} == ExBanking.withdraw("Mall", 15, "USD")
    end

    test "run with not existing user" do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw("Hall", 15, "USD")
    end

    test "run with wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.withdraw(nil, nil, nil)
    end

    test "run with request limit" do
      ExBanking.create_user("Limitted_withdraw_user")
      ExBanking.deposit("Limitted_withdraw_user", 50, "USD")
      Enum.each(1..10, fn _ -> ExBanking.Counter.increment("Limitted_withdraw_user") end)

      assert {:error, :too_many_requests_to_user} ==
               ExBanking.withdraw("Limitted_withdraw_user", 50, "USD")
    end
  end

  describe "get_balance/2" do
    test "run" do
      ExBanking.create_user("Cur")
      ExBanking.deposit("Cur", 10, "USD")

      assert {:ok, 10} == ExBanking.get_balance("Cur", "USD")
    end

    test "run with not existing user" do
      assert {:error, :user_does_not_exist} == ExBanking.get_balance("Max", "USD")
    end

    test "run with wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.get_balance(nil, nil)
    end

    test "run with request limit" do
      ExBanking.create_user("Limitted_get_balance_user")
      ExBanking.deposit("Limitted_get_balance_user", 50, "USD")
      Enum.each(1..10, fn _ -> ExBanking.Counter.increment("Limitted_get_balance_user") end)

      assert {:error, :too_many_requests_to_user} ==
               ExBanking.get_balance("Limitted_get_balance_user", "USD")
    end
  end

  describe "send/4" do
    test "run" do
      ExBanking.create_user("Sender")
      ExBanking.create_user("Receiver")
      ExBanking.deposit("Sender", 20, "USD")

      assert {:ok, 10.0, 10.0} == ExBanking.send("Sender", "Receiver", 10, "USD")
    end

    test "run with wrong arguments" do
      assert {:error, :wrong_arguments} == ExBanking.send(nil, nil, nil, nil)
    end

    test "run with not enough money" do
      ExBanking.create_user("Sender_NEM")
      ExBanking.create_user("Receiver_NEM")
      ExBanking.deposit("Sender_NEM", 20, "USD")

      assert {:error, :not_enough_money} ==
               ExBanking.send("Sender_NEM", "Receiver_NEM", 40, "USD")
    end

    test "run with sender not found" do
      ExBanking.create_user("Receiver_found")
      ExBanking.deposit("Receiver_found", 20, "USD")

      assert {:error, :sender_does_not_exist} ==
               ExBanking.send("Sender_not_found", "Receiver_found", 40, "USD")
    end

    test "run with receiver not found" do
      ExBanking.create_user("Sender_found")
      ExBanking.deposit("Sender_found", 20, "USD")

      assert {:error, :receiver_does_not_exist} ==
               ExBanking.send("Sender_found", "Receiver_not_found", 40, "USD")
    end

    test "run with request limit for sender" do
      ExBanking.create_user("Limitted_sender_user")
      ExBanking.create_user("Dummy_receiver_user")
      ExBanking.deposit("Limitted_sender_user", 50, "USD")
      ExBanking.deposit("Dummy_receiver_user", 50, "USD")
      Enum.each(1..10, fn _ -> ExBanking.Counter.increment("Limitted_sender_user") end)

      assert {:error, :too_many_requests_to_sender} ==
               ExBanking.send("Limitted_sender_user", "Dummy_receiver_user", 25, "USD")
    end

    test "run with request limit for receiver" do
      ExBanking.create_user("Dummy_sender_user")
      ExBanking.create_user("Limitted_receiver_user")
      ExBanking.deposit("Dummy_sender_user", 50, "USD")
      ExBanking.deposit("Limitted_receiver_user", 50, "USD")
      Enum.each(1..10, fn _ -> ExBanking.Counter.increment("Limitted_receiver_user") end)

      assert {:error, :too_many_requests_to_receiver} ==
               ExBanking.send("Dummy_sender_user", "Limitted_receiver_user", 25, "USD")
    end
  end
end
