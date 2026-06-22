import Config

config :kairo42,
  ecto_repos: [Kairo42.Repo],
  generators: [timestamp_type: :utc_datetime]

config :kairo42, Kairo42Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Kairo42Web.ErrorHTML, json: Kairo42Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: Kairo42.PubSub,
  live_view: [signing_salt: "HkyDpsWx"]

config :kairo42, Kairo42.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.25.4",
  kairo42: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :libcluster,
  topologies: [
    gossip: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        secret: "devsecret"
      ]
    ]
  ]

config :tailwind,
  version: "4.1.12",
  kairo42: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :kairo42, Kairo42.Command.Workflow.Actor, repository: Kairo42.Command.Workflow.Repository

import_config "#{config_env()}.exs"
