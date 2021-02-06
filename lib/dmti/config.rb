module Dmti
  class Config
    include LazyConfig::Loader

    # LazyConfig::Loader
    self.environment_aware = false

    class << self
      # LazyConfig::Loader
      def config_filename
        '.dmti.yaml'
      end
    end
  end
end
