defmodule AutoTest do
  use ExUnit.Case
  doctest Auto

  setup do
    Redix.command(:redix, ["FLUSHDB"])
    :ok
  end

  test "insert keys for prefixes and data" do
    base_key = "test:1"
    text = "The Rain"
    id = "123"
    Auto.insert(base_key, text, id, {id, text})

    assert 1 == Redix.command!(:redix, ["EXISTS", base_key])

    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:th"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:he"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:the"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:ra"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:ai"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:in"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:rai"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:ain"])
    assert 1 == Redix.command!(:redix, ["EXISTS", "#{base_key}:rain"])

    assert 0 == Redix.command!(:redix, ["EXISTS", "#{base_key}:t"])
    assert 0 == Redix.command!(:redix, ["EXISTS", "#{base_key}:r"])
  end

  test "data is stored" do
    base_key = "test:1"
    text = "The Rain"
    id = "123"
    data = {id, text}
    Auto.insert(base_key, text, id, data)

    assert [id] == Redix.command!(:redix, ["ZRANGE", "#{base_key}:th", "0", "-1"])

    encoded = List.first(Redix.command!(:redix, ["HMGET", base_key, id]))
    assert data == :erlang.binary_to_term(encoded)
  end

  test "single word matching" do
    base_key = "test:1"
    Auto.insert(base_key, "The Rain", 1, {1, "The Rain"})
    Auto.insert(base_key, "Rainman", 2, {2, "Rainman"})
    Auto.insert(base_key, "The Rainforest", 3, {3, "The Rainforest"})

    assert Auto.match(base_key, "rain") |> Enum.count() == 3
    assert Auto.match(base_key, "he") |> Enum.count() == 2
    assert Auto.match(base_key, "forest") |> Enum.count() == 1
    assert Auto.match(base_key, "man") |> Enum.count() == 1
    assert Auto.match(base_key, "man") == [{2, "Rainman"}]
  end

  test "multiple words matching" do
    base_key = "test:1"
    Auto.insert(base_key, "The Rain", 1, {1, "The Rain"})
    Auto.insert(base_key, "Rainman", 2, {2, "Rainman"})
    Auto.insert(base_key, "The Rainforest", 3, {3, "The Rainforest"})

    assert Auto.match(base_key, "the forest") == [{3, "The Rainforest"}]
  end

  test "ignore short words, match the rest" do
    base_key = "test:1"
    Auto.insert(base_key, "The Rain", 1, {1, "The Rain"})
    Auto.insert(base_key, "Rainman", 2, {2, "Rainman"})
    Auto.insert(base_key, "The Rainforest", 3, {3, "The Rainforest"})

    assert Auto.match(base_key, "e i man o") |> Enum.count() == 1
  end
end
