defmodule AutoTest do
  use ExUnit.Case
  doctest Auto.Redis

  setup do
    Redix.command(:redix, ["FLUSHALL"])
    :ok
  end

  test "insert keys for prefixes and data" do
    base_key = "test:1"
    text = "The Rain"
    id = "123"
    Auto.Redis.insert(base_key, text, id, {id, text})

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
    Auto.Redis.insert(base_key, text, id, data)

    assert [id] == Redix.command!(:redix, ["ZRANGE", "#{base_key}:th", "0", "-1"])

    encoded = List.first(Redix.command!(:redix, ["HMGET", base_key, id]))
    assert data == :erlang.binary_to_term(encoded)
  end

  test "insert in batch" do
    base_key = "test:1"

    [
      ["Edge of Tomorow", 1, :data1],
      ["Rainman", 2, :data2],
      ["Mission Impossible", 3, :data3]
    ]
    |> Auto.Redis.insert(base_key)

    assert Redix.command!(:redix, ["EXISTS", base_key, "1"])
    assert Redix.command!(:redix, ["EXISTS", base_key, "2"])
    assert Redix.command!(:redix, ["EXISTS", base_key, "3"])
  end

  test "insert from stream" do
    base_key = "test:1"

    Stream.uniq([
      ["Edge of Tomorow", 1, :data1],
      ["Rainman", 2, :data2],
      ["Mission Impossible", 3, :data3]
    ])
    |> Auto.Redis.insert(base_key)

    assert Redix.command!(:redix, ["EXISTS", base_key, "1"])
    assert Redix.command!(:redix, ["EXISTS", base_key, "2"])
    assert Redix.command!(:redix, ["EXISTS", base_key, "3"])
  end

  test "single word matching" do
    base_key = "test:1"

    [
      ["The Rain", 1, {1, "The Rain"}],
      ["Rainman", 2, {2, "Rainman"}],
      ["The Rainforest", 3, {3, "The Rainforest"}]
    ]
    |> Auto.Redis.insert(base_key)

    assert Auto.Redis.match(base_key, "rain") |> Enum.count() == 3
    assert Auto.Redis.match(base_key, "he") |> Enum.count() == 2
    assert Auto.Redis.match(base_key, "forest") |> Enum.count() == 1
    assert Auto.Redis.match(base_key, "man") |> Enum.count() == 1
    assert Auto.Redis.match(base_key, "man") == [{2, "Rainman"}]
  end

  test "multiple words matching" do
    base_key = "test:1"

    [
      ["The Rain", 1, {1, "The Rain"}],
      ["Rainman", 2, {2, "Rainman"}],
      ["The Rainforest", 3, {3, "The Rainforest"}]
    ]
    |> Auto.Redis.insert(base_key)

    assert Auto.Redis.match(base_key, "the forest") == [{3, "The Rainforest"}]
  end

  test "ignore short words, match the rest" do
    base_key = "test:1"

    [
      ["The Rain", 1, {1, "The Rain"}],
      ["Rainman", 2, {2, "Rainman"}],
      ["The Rainforest", 3, {3, "The Rainforest"}]
    ]
    |> Auto.Redis.insert(base_key)

    assert Auto.Redis.match(base_key, "e i man o") |> Enum.count() == 1
  end
end
