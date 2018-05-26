# exAuto

A super fast Elixir in-memory autocomplete using Redis.

It uses the technique described in the classic post by *antirez* “[Auto Complete with Redis](http://oldblog.antirez.com/post/autocomplete-with-redis.html)
” with one important improvement: you can find a text by any part of it, not just its prefix and not just the beginning of individual words.

For example, the phrase “The Green Rainforest” can be found by searching for “forest”, “green”, “info”, “een”, “rest”, etc.

It achieves that by slicing and storing the word in chunks of variable size. For instance “green” will generate "gr", "re", "ee", "en", "gre", "ren", "een", "gree", "reen", and "green".


## Memory Usage

The amount of memory used will differ depending of the number and legth of your terms and the data stored with them, but you can expect to need approximately `120 x <bytes of your data>`.

For example. the test data (cities.csv) of 65'500 rows and 1.2 MB uses a total of 147 MB on Redis.

The length of the `base_key` is not an important factor for that size, so it doesn't matter much if you use single letter of a full word.
