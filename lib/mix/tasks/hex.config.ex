defmodule Mix.Tasks.Hex.Config do
  use Mix.Task

  @shortdoc "Reads, updates or deletes local Hex config"

  @moduledoc """
  Reads, updates or deletes local Hex configuration.

      mix hex.config KEY [VALUE]

  ## Config keys

    * `api_key` - Your API key. If you are authenticated this config will override
      the API key used for your authenticated user. Can be also be overridden by
      setting the environment variable `HEX_API_KEY`
    * `api_url` - Hex API URL. Can be overridden by setting the environment
      variable `HEX_API_URL` (Default: `"https://hex.pm/api"`)
    * `offline` - If set to true Hex will not fetch the registry or packages and
      will instead use locally cached files if they are available. Can be
      overridden by setting the environment variable `HEX_OFFLINE` (Default:
      `false`)
    * `unsafe_https` - If set to true Hex will not verify HTTPS certificates.
      Can be overridden by setting the environment variable `HEX_UNSAFE_HTTPS`
      (Default: `false`)
    * `unsafe_registry` - If set to true Hex will not verify the registry
      signature against the repository's public key. Can be overridden by
      setting the environment variable `HEX_UNSAFE_REGISTRY` (Default:
      `false`)
    * `http_proxy` - HTTP proxy server. Can be overridden by setting the
      environment variable `HTTP_PROXY`
    * `https_proxy` - HTTPS proxy server. Can be overridden by setting the
      environment variable `HTTPS_PROXY`
    * `http_concurrency` - Limits the number of concurrent HTTP requests in
      flight. Can be overridden by setting the environment variable
      `HEX_HTTP_CONCURRENCY` (Default: `8`)
    * `http_timeout` - Sets the timeout for HTTP requests in seconds. Can be
      overridden by setting the environment variable `HEX_HTTP_TIMEOUT`

  `HEX_HOME` environment variable can be set to point to the directory where Hex
  stores the cache and configuration (Default: `~/.hex`)

  ## Command line options

    * `--delete` - Remove a specific config key
  """

  @switches [delete: :boolean]
  @valid_keys [
    "api_key",
    "api_url",
    "offline",
    "unsafe_https",
    "unsafe_registry",
    "http_proxy",
    "https_proxy",
    "http_concurrency",
    "http_timeout"
  ]

  @impl true
  def run(args) do
    Hex.start()
    {opts, args} = Hex.OptionParser.parse!(args, strict: @switches)

    case args do
      [] ->
        list()

      ["$" <> _key | _] ->
        Mix.raise("Invalid key name")

      [key] ->
        if opts[:delete] do
          delete(key)
        else
          read(key)
        end

      [key, value] ->
        set(key, value)

      _ ->
        Mix.raise("""
        Invalid arguments, expected:

        mix hex.config KEY [VALUE]
        """)
    end
  end

  defp list() do
    Enum.each(config(), fn {key, value} ->
      Hex.Shell.info("#{key}: #{inspect(value, pretty: true)}")
    end)
  end

  defp read(key) do
    case Keyword.fetch(config(), :"#{key}") do
      {:ok, value} ->
        Hex.Shell.info(inspect(value, pretty: true))

      :error ->
        Mix.raise("Config does not contain key #{key}")
    end
  end

  defp delete(key) do
    Hex.Config.remove([String.to_atom(key)])
  end

  defp set(key, value) when key in @valid_keys do
    Hex.Config.update([{:"#{key}", value}])
  end

  defp set(key, _value) do
    Mix.raise("Invalid key #{key}")
  end

  defp config() do
    Hex.Config.read()
    |> Enum.reject(fn {key, _value} -> String.starts_with?(Atom.to_string(key), "$") end)
    |> Keyword.delete(:encrypted_key)
  end
end
