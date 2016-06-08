defmodule ExMangaDownloadr do
  require Logger

  @user_agent   Application.get_env(:ex_manga_downloadr, :user_agent)
  @http_timeout 60_000

  # will retry failed fetches over 50 times, sleeping 1 second between each retry
  @max_retries  50
  @time_to_wait_to_fetch_again 1_000
  @http_errors ["retry_later", "connection_closing", "req_timedout"]

  @doc """
  All HTTPotion.Response bodies should go through this gunzip process
  """
  def gunzip(body, headers) do
    if headers[:"Content-Encoding"] == "gzip" do
      :zlib.gunzip(body)
    else
      body
    end
  end

  @doc """
  All HTTPotion requests should use this set of options
  """
  def http_headers do
    [
      headers: ["User-Agent": @user_agent, "Accept-encoding": "gzip", "Connection": "keep-alive"],
      timeout: @http_timeout
    ]
  end

  def retryable_http_get(url, 0), do: raise "Failed to fetch from #{url} after #{@max_retries} retries."
  def retryable_http_get(url, retries \\ @max_retries) when retries > 0 do
    try do
      Logger.debug("Fetching from #{url} for the #{@max_retries - retries} time.")
      response = HTTPotion.get(url, ExMangaDownloadr.http_headers)
      case response do
        %HTTPotion.Response{ body: _, headers: _, status_code: status } when status > 499 ->
          raise %HTTPotion.HTTPError{message: "req_timedout"}
        _ ->
          response
      end
    rescue
      error in HTTPotion.HTTPError ->
        case error do
          %HTTPotion.HTTPError{message: message} when message in @http_errors ->
            :timer.sleep(@time_to_wait_to_fetch_again)
            retryable_http_get(url, retries - 1)
          _ -> raise error
        end
    end
  end

  defmacro fetch(link, do: expression) do
    quote do
      case ExMangaDownloadr.retryable_http_get(unquote(link)) do
        %HTTPotion.Response{ body: body, headers: headers, status_code: 200 } ->
          { :ok, body |> ExMangaDownloadr.gunzip(headers) |> unquote(expression) }
      end
    end
  end

  ## Phoenix like "use ExMangaDownloadr, :mangareader" for aliasing

  def mangareader do
    quote do
      alias ExMangaDownloadr.MangaReader.IndexPage
      alias ExMangaDownloadr.MangaReader.ChapterPage
      alias ExMangaDownloadr.MangaReader.Page
    end
  end

  def mangafox do
    quote do
      alias ExMangaDownloadr.Mangafox.IndexPage
      alias ExMangaDownloadr.Mangafox.ChapterPage
      alias ExMangaDownloadr.Mangafox.Page
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
