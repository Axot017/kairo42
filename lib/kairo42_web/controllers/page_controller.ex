defmodule Kairo42Web.PageController do
  use Kairo42Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
