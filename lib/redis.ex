defmodule Auto.Redis do
  alias Auto.Utils

  @min_length 2
  @cache_time 600
  @chunk_every 100

  defp encode(data) do
    :erlang.term_to_binary(data)
  end

  defp decode(""), do: nil
  defp decode(nil), do: nil

  defp decode(data) do
    :erlang.binary_to_term(data)
  end

  @doc """
  Process and insert terms from a stream or an enumerable of terms with the
  format `[term, id, data]` into Redis.

  It generates and send the insertion commands of `@chunk_every` terms
  each time.
  """
  def insert(stream_or_enumerable, base_key) do
    stream_or_enumerable
    |> Stream.chunk_every(@chunk_every)
    |> Stream.map(fn items ->
      cmds = Enum.reduce(items, [], fn item, acc -> insert_cmds(base_key, item, acc) end)
      Redix.pipeline!(:redix, cmds)
    end)
    |> Stream.run()
  end

  @doc """
  Process and insert one term into Redis.
  """
  def insert(base_key, text, id, data) do
    cmds = insert_cmds(base_key, [text, id, data])
    Redix.pipeline!(:redix, cmds)
  end

  defp insert_cmds(base_key, [text, id, data], acc \\ []) do
    text
    |> Utils.normalize()
    |> Utils.split()
    |> insert_term_cmds(base_key, id, acc)
    |> Enum.concat([["HSET", base_key, id, encode(data)]])
  end

  defp insert_term_cmds([], _key, _id, acc), do: acc

  defp insert_term_cmds([term | rest], key, id, acc) do
    acc =
      term
      |> Utils.slice_and_dice()
      |> Enum.filter(fn x -> String.length(x) >= @min_length end)
      |> Enum.map(fn prefix -> ["ZADD", "#{key}:#{prefix}", "0", id] end)
      |> Enum.concat(acc)

    insert_term_cmds(rest, key, id, acc)
  end

  # ---------------------------------------------------------------------------

  def match(base_key, term) do
    terms = term |> Utils.normalize() |> Utils.split()

    case Enum.count(terms) do
      0 -> []
      1 -> match_terms(base_key, List.first(terms))
      _ -> match_terms(base_key, terms)
    end
  end

  defp match_terms(key, term) when is_binary(term) do
    resp = Redix.command!(:redix, ["ZRANGE", "#{key}:#{term}", "0", "-1"])

    case resp do
      [] -> []
      ids -> get_data(key, ids)
    end
  end

  defp match_terms(key, terms) when is_list(terms) do
    combkey = "#{key}:#{terms |> Enum.join("|")}"
    keys = terms |> Enum.map(fn term -> "#{key}:#{term}" end)

    [1, 1, ids] =
      Redix.pipeline!(:redix, [
        ["ZINTERSTORE", combkey, length(terms)] ++ keys,
        ["EXPIRE", combkey, @cache_time],
        ["ZRANGE", combkey, "0", "-1"]
      ])

    case ids do
      [] -> []
      _ -> get_data(key, ids)
    end
  end

  defp get_data(key, ids) when is_list(ids) do
    Redix.command!(:redix, ["HMGET", key] ++ ids)
    |> Enum.map(&decode/1)
  end

  @doc """
  Recieves a csv file with 'id,term' on each line,
  and process and insert them as `[term, id, {id, term}]`.
  """
  def load_from_file(filename, base_key) do
    filename
    |> File.stream!()
    |> Stream.map(fn x ->
      [id, term] = String.split(x, ",")
      [term, id, {id, term}]
    end)
    |> insert(base_key)
  end
end
