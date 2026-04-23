defmodule BackendWeb.Plugs.JsonParser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Only process POST/PUT/PATCH requests on API routes that might have JSON bodies
    if conn.method in ["POST", "PUT", "PATCH"] &&
       String.starts_with?(conn.request_path, "/api") &&
       conn.method != "GET" do

      # Skip if already parsed by Plug.Parsers
      case conn.body_params do
        %Plug.Conn.Unfetched{} ->
          # Body hasn't been parsed yet, try to parse it manually
          attempt_json_parse(conn)
        _already_parsed ->
          # Already parsed, just use it
          conn
      end
    else
      conn
    end
  end

  defp attempt_json_parse(conn) do
    try do
      case Plug.Conn.read_body(conn, length: 1_000_000) do
        {:ok, body, _conn} when is_binary(body) and byte_size(body) > 0 ->
          case Jason.decode(body) do
            {:ok, json} when is_map(json) ->
              # Merge JSON data into params
              merged_params = Map.merge(conn.params, json)
              %{conn | params: merged_params}
            _error ->
              conn
          end
        _other ->
          conn
      end
    rescue
      _e -> conn
    end
  end
end
