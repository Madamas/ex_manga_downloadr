defmodule ExMangaDownloadr.MangaSource.Mangafox.ChapterPage do
  def fetch_pages(html, chapter_link) do
    [_page|link_template] = chapter_link |> String.split("/") |> Enum.reverse

    html
    |> Floki.find("div[id='top_center_bar'] option")
    |> Floki.attribute("value")
    |> Enum.reject(fn page_number -> page_number == "0" end)
    |> Enum.map(fn page_number -> 
      ["#{page_number}.html"|link_template]
        |> Enum.reverse
        |> Enum.join("/")
    end)
  end
end
