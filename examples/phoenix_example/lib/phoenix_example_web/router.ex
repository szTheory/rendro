defmodule PhoenixExampleWeb.Router do
  use PhoenixExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixExampleWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", PhoenixExampleWeb do
    pipe_through :api

    get "/download", PDFController, :download
    get "/preview", PDFController, :preview
    get "/branded/download", PDFController, :branded_download
    get "/branded/preview", PDFController, :branded_preview
  end
end
