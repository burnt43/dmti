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

      def database_pathname
        @database_pathname ||= Pathname.new(config.dig('config', 'database'))
      end

      def music_transcription_pathname
        @music_transcription_pathname ||= Pathname.new(config.dig('config', 'music_transcription_dir'))
      end
    end
  end
end
