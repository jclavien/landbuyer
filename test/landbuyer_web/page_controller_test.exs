defmodule LandbuyerWeb.PageControllerTest do
  use LandbuyerWeb.ConnCase

  test "GET /en", %{conn: conn} do
    conn = get(conn, ~p"/en")
    assert html_response(conn, 200) =~ "Active adventures"
  end
end
