defmodule Auto do
  @min_length 2
  @cache_time 600

  defp redis(cmd) do
    Redix.command!(:redix, cmd)
  end

  defp normalize(text) do
    text
    |> String.trim()
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> Slug.slugify(separator: " ")
  end

  defp encode(data) do
    :erlang.term_to_binary(data)
  end

  defp decode(""), do: nil
  defp decode(nil), do: nil

  defp decode(data) do
    :erlang.binary_to_term(data)
  end

  def insert(base_key, text, id, data) do
    insert_data(base_key, id, data)
    insert_text_prefixes(base_key, text, id)
  end

  defp insert_data(key, id, data) do
    redis(["HSET", key, id, encode(data)])
  end

  defp insert_text_prefixes(key, text, id) do
    text
    |> normalize
    |> String.split()
    |> Enum.each(fn term -> insert_term_prefixes(key, term, id) end)
  end

  defp insert_term_prefixes(key, term, id) do
    slice_and_dice(term)
    |> Enum.filter(fn x -> String.length(x) >= @min_length end)
    |> Enum.map(fn prefix -> insert_prefix(key, prefix, id) end)
  end

  defp insert_prefix(key, prefix, id) do
    redis(["ZADD", "#{key}:#{prefix}", "0", id])
  end

  def match(base_key, term) do
    terms =
      normalize(term)
      |> String.split()
      |> Enum.filter(fn term -> String.length(term) >= @min_length end)

    case length(terms) do
      0 -> []
      1 -> match_terms(base_key, List.first(terms))
      _ -> match_terms(base_key, terms)
    end
  end

  defp match_terms(key, term) when is_binary(term) do
    case redis(["ZRANGE", "#{key}:#{term}", "0", "-1"]) do
      [] -> []
      ids -> get_data(key, ids)
    end
  end

  defp match_terms(key, terms) when is_list(terms) do
    combkey = "#{key}:#{terms |> Enum.join("|")}"
    keys = terms |> Enum.map(fn term -> "#{key}:#{term}" end)

    redis(["ZINTERSTORE", combkey, length(terms)] ++ keys)
    redis(["EXPIRE", combkey, @cache_time])

    case redis(["ZRANGE", combkey, "0", "-1"]) do
      [] -> []
      ids -> get_data(key, ids)
    end
  end

  defp get_data(key, ids) when is_list(ids) do
    redis(["HMGET", key] ++ ids)
    |> Enum.map(&decode/1)
  end

  @doc """
  Find all the possible slices of a term of at least `@min_length` characters.

  This'll allow us to find the term by any part of it, not just the prefix.

  ## Examples
      iex> Auto.slice_and_dice("aliens")
      ["al", "li", "ie", "en", "ns", "ali", "lie", "ien", "ens",
      "alie", "lien", "iens", "alien", "liens", "aliens"]
  """
  def slice_and_dice(term, acc \\ [], wsize \\ @min_length) do
    cond do
      wsize <= String.length(term) ->
        slice_and_dice(
          term,
          dice(term, acc, wsize),
          wsize + 1
        )

      true ->
        acc
    end
  end

  defp dice(term, acc, wsize, start \\ 0) do
    sub = String.slice(term, start, wsize)

    cond do
      String.length(sub) >= wsize ->
        dice(term, acc ++ [sub], wsize, start + 1)

      true ->
        acc
    end
  end
end
