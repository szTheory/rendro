defmodule PhoenixExampleWeb.Router do
  use PhoenixExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixExampleWeb do
    pipe_through :api

    get "/download", PDFController, :download
    get "/preview", PDFController, :preview
  end
end
