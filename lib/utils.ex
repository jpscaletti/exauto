defmodule Auto.Utils do
  @min_length 2

  def normalize(term) do
    term
    |> String.trim()
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> Slug.slugify(separator: " ")
  end

  def split(term) do
    term
    |> String.split()
    |> Enum.filter(fn term -> String.length(term) >= @min_length end)
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
