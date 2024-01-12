defmodule ParadiseWeb.Router do
  use ParadiseWeb, :router

  import ParadiseWeb.AstronautAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ParadiseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_astronaut
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ParadiseWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ParadiseWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:paradise, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: ParadiseWeb.Telemetry,
        additional_pages: [
          ecsx: ECSx.LiveDashboard.Page
        ]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ParadiseWeb do
    pipe_through [:browser, :redirect_if_astronaut_is_authenticated]

    live_session :redirect_if_astronaut_is_authenticated,
      on_mount: [{ParadiseWeb.AstronautAuth, :redirect_if_astronaut_is_authenticated}] do
      live "/astronauts/register", AstronautRegistrationLive, :new
      live "/astronauts/log_in", AstronautLoginLive, :new
      live "/astronauts/reset_password", AstronautForgotPasswordLive, :new
      live "/astronauts/reset_password/:token", AstronautResetPasswordLive, :edit
    end

    post "/astronauts/log_in", AstronautSessionController, :create
  end

  scope "/", ParadiseWeb do
    pipe_through [:browser, :require_authenticated_astronaut]

    live_session :require_authenticated_astronaut,
      on_mount: [{ParadiseWeb.AstronautAuth, :ensure_authenticated}] do
      live "/game", GameLive
      live "/astronauts/settings", AstronautSettingsLive, :edit
      live "/astronauts/settings/confirm_email/:token", AstronautSettingsLive, :confirm_email
    end
  end

  scope "/", ParadiseWeb do
    pipe_through [:browser]

    delete "/astronauts/log_out", AstronautSessionController, :delete

    live_session :current_astronaut,
      on_mount: [{ParadiseWeb.AstronautAuth, :mount_current_astronaut}] do
      live "/astronauts/confirm/:token", AstronautConfirmationLive, :edit
      live "/astronauts/confirm", AstronautConfirmationInstructionsLive, :new
    end
  end
end
