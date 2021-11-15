defmodule WebhookEndpointTest do
  use ExUnit.Case
  use Plug.Test

  alias Webhook.Endpoint

  @opts Endpoint.init([])

  doctest Webhook.Endpoint

  test "ping" do
    validate_url_call(200, :get, "/ping")
  end

  test "lightning post no parameters" do
    validate_url_call(200, :post, "/lightning")
  end

  test "lightning post with quantity integer" do
    validate_url_call(200, :post, "/lightning", %{"strikes" => 10})
  end

  test "lightning post with quantity string" do
    validate_url_call(200, :post, "/lightning", %{"strikes" => "10"})
  end

  test "strip post" do
    validate_url_call(200, :post, "/strip", %{"quantity" => 10, "start" => 0})
  end

  test "invalid strip post" do
    validate_url_call(400, :post, "/strip")
  end

  test "color post" do
    validate_url_call(200, :post, "/color", %{"color" => "#A253FC"})
  end

  test "invalid color post" do
    validate_url_call(400, :post, "/color")
  end

  test "validate handling unknown requests" do
    validate_url_call(404, :get, "/random_url")
    validate_url_call(404, :put, "/random_put")
    validate_url_call(404, :post, "/random_post")
  end

  defp validate_url_call(http_code, rest_req, url, data \\ "") do
    conn =
      conn(rest_req, url, data)
      |> Endpoint.call(@opts)

    assert conn.state == :sent
    assert conn.status == http_code
  end
end
