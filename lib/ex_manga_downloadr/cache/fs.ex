defmodule ExMangaDownloadr.Cache.FS do
  @behaviour ExMangaDownloadr.Cache.Behaviour

  def call(id, options, cb) do
    read(id, options)
    |> do_call(id, options, cb)
  end

  def read(id, options) do
    case cache_path(id, options) |> File.read do
      {:ok, contents} -> contents
      _ -> :cache_miss
    end
  end

  def write(id, contents, options) do
    cache_path(id, options)
    |> File.write!(contents)
  end

  defp cache_path(id, options) do
    Path.join(options[:dir], filename(id))
  end

  defp filename(id) do
    :crypto.hash(:md5, id)
    |> Base.encode16()
  end

  defp do_call(:cache_miss, id, options, cb) do
    value = cb.(:cache_miss, "")
    extract = options[:extractor] || &(&1)

    write id, extract.(value), options

    value
  end

  defp do_call(contents, _, _, cb) do
    cb.(:cache_hit, contents)
  end
end
