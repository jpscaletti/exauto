defmodule Auto.Data do
  @test_data [
    {"4", "CSS Mastery Advanced Web Standards Solutions Third Edition"},
    {"5", "Test Review · Best-Self Reviews · 15Five"},
    {"9", "Silicon Valley 5x05"},
    {"12", "Silicon Valley 5x08"},
    {"14", "Reservoir Dogs"},
    {"17", "texture01"},
    {"18", "Westworld 2x02"},
    {"19", "Effective JavaScript"},
    {"20", "Eloquent JavaScript (2011)"},
    {"21", "CSS_Secrets"},
    {"22", "Westworld 2x04"},
    {"24", "The_Little_Elixir_&_OTP_Guidebook"},
    {"25", "Westworld 2x05"},
    {"26", "Westworld 2x01"},
    {"35", "JavaScript Web Applications (2011)"},
    {"36", "Simply JavaScript (2007) [SitePoint]"},
    {"39", "stacking_the_bricks"},
    {"40", "Design - QA Pre Production Iterations (Draft)"},
    {"42", "Silicon Valley 5x01"},
    {"46", "JavaScript The Definitive Guide (2006)"},
    {"48", "JavaScript The Good Parts (2010)"},
    {"49", "texture05"},
    {"50", "Using_the_HTML5_Filesystem_API"},
    {"52", "programming-phoenix-1-4_b1_0"},
    {"53", "Silicon Valley 5x06"},
    {"54", "It Comes At Night"},
    {"55", "HTML5 For Web Designers (2010) Jeremy Keith [ABA]"},
    {"56", "Evans - Beginning Arduino Programming"},
    {"57", "mostly-adequate-guide"},
    {"58", "Silicon Valley 5x02"},
    {"59", "Silicon Valley 5x04"},
    {"63", "JavaScript Patterns (2010)"},
    {"66", "Silicon Valley 5x07"},
    {"68", "texture04"},
    {"74", "Silicon Valley 5x03"},
    {"75", "Westworld 2x03"},
    {"79", "JavaScript The Definitive Guide (2011) 6th ed"},
    {"80", "magicsuggest"},
    {"84", "DeDRM_tools-master"},
    {"86", "texture03"},
    {"87", "CSS The Definitive Guide Visual Presentation for the Web, 4th Edition"},
    {"88", "Radical Focus - Christina Wodtke"},
    {"89", "texture02"},
    {"90", "Badass Making Users Awesome"},
    {"91", "Head First Ruby_ A Brain-Friendly Guide"},
    {"96", "The Ultimate Guide to Remote Work"}
  ]

  def test_data() do
    @test_data
  end

  def load_test_data() do
    @test_data |> Enum.each(fn pair -> load_title(pair) end)
  end

  defp load_title({id, title} = data) do
    Auto.insert("tags:1", title, id, data)
  end
end
