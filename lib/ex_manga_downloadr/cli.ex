defmodule ExMangaDownloadr.CLI do
  alias ExMangaDownloadr.Workflow

  def main(args) do
    try do
      args
      |> parse_args
      |> process
    rescue
      e in ExMangaDownloadr.Workflow ->
        IO.puts e.message
        System.halt 0
    end
  end

  defp parse_args(args) do
    parse = OptionParser.parse(args,
      switches: [url: :string, directory: :string, test: :boolean],
      aliases: [u: :url, d: :directory, t: :boolean]
    )
    case parse do
      {[test: true], _, _} ->
        directory = System.get_env("TEST_DIRECTORY") || "/tmp/ex_one_punch_man"
        process_test(directory, "http://www.mangareader.net/onepunch-man")
      {[url: url, directory: directory], _, _} -> process(directory, url)
      {_, _, _ } -> process(:help)
    end
  end

  defp process(:help) do
    IO.puts """
      usage:
        ./ex_manga_downloadr -u http://www.mangareader.net/boku-wa-ookami -d /tmp/boku-wa-ookami

      As mangafox doesn't support too much concurrency, slow it down like this:
        POOL_SIZE=10 ./ex_manga_downloadr -u http://mangafox.me/manga/onepunch_man/ -d /tmp/onepunch

      To benchmark you use the test mode like this:

        ./ex_manga_downloadr --test

      this will use One-Punch Man as a sample test and skip the actual download, optimize and compile pdf steps.

      You can also turn on cache mode like this:

        CACHE_HTTP=true ./ex_manga_downloadr  -u http://www.mangareader.net/boku-wa-ookami -d /tmp/boku-wa-ookami

      That way you can resume operations if you had to interrupt it before.
    """
    System.halt(0)
  end

  defp process(directory, url) do
    File.mkdir_p! directory
    ExMangaDownloadr.create_cache_dir

    manga_name = directory |> String.split("/") |> List.last
    url
      |> scrap_and_download(directory)
      |> Workflow.optimize_images
      |> Workflow.compile_pdfs(manga_name)
      |> finish_process
  end

  defp scrap_and_download(url, directory) do
    url
      |> Workflow.determine_source
      |> Workflow.chapters
      |> Workflow.pages
      |> Workflow.images_sources
      |> Workflow.process_downloads(directory)
  end

  defp process_test(directory, url) do
    File.mkdir_p! directory
    ExMangaDownloadr.create_cache_dir

    url
      |> scrap_and_download(directory)

    directory
      |> finish_process
  end

  defp finish_process(directory) do
    IO.puts "Finished, please check your PDF files at #{directory}."
    System.halt(0)
  end
end
