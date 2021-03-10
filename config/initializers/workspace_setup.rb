Rails.configuration.to_prepare do
  WorkspaceConfig.setup unless ENV['RAILS_ENV'] == 'test'
end
