Rails.application.configure do
  # Code wird nicht neu geladen zwischen Requests
  config.enable_reloading = false

  # Eager loading für bessere Performance
  config.eager_load = true

  # Vollständige Fehlermeldungen unterdrücken
  config.consider_all_requests_local = false

  # Caching aktivieren
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # Assets
  config.assets.compile = false

  # Logging
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Mailer
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV["APP_HOST"] }
  config.action_mailer.smtp_settings = {
    address:              "smtp.mailbox.org",
    port:                 587,
    user_name:            ENV["MAIL_USERNAME"],
    password:             ENV["MAIL_PASSWORD"],
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # ActiveStorage
  config.active_storage.service = :local

  # Fehler bei fehlenden Master-Key
  config.require_master_key = true

  # Host-Validierung – alle Subdomains erlauben
  config.hosts << /.*\.kontova\.de/
  config.hosts << "kontova.de"
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.default_url_options = { host: ENV["APP_HOST"], protocol: "https" }
end
