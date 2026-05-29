defmodule PhoenixExampleWeb.PageController do
  use PhoenixExampleWeb, :controller

  @chooser_html ~S"""
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Rendro Demo</title>
    </head>
    <body>
      <h1>Rendro Demo</h1>
      <p>Choose a PDF to render with Rendro.</p>
      <ul>
        <li><a href="/download">Unbranded invoice - attachment download</a></li>
        <li><a href="/preview">Unbranded invoice - inline preview</a></li>
        <li><a href="/branded/download">Branded invoice with logo + custom font - attachment download</a></li>
        <li><a href="/branded/preview">Branded invoice with logo + custom font - inline preview</a></li>
        <li><a href="/statement/download">Statement - attachment download</a></li>
        <li><a href="/statement/preview">Statement - inline preview</a></li>
        <li><a href="/receipt/download">Receipt - attachment download</a></li>
        <li><a href="/receipt/preview">Receipt - inline preview</a></li>
        <li><a href="/certificate/download">Certificate - attachment download</a></li>
        <li><a href="/certificate/preview">Certificate - inline preview</a></li>
      </ul>
    </body>
  </html>
  """

  def index(conn, _params) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, @chooser_html)
  end
end
