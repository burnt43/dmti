module Dmti
  class << self
    def db
      @db ||= SQLite3::Database.new(Dmti::Config.database_pathname.to_s)
    end

    def filenames_in_music_transcription_dir
      @filenames_in_music_transcription_dir ||=
        Dmti::Config.music_transcription_pathname.entries.map(&:to_s).reject do |entry|
          entry.start_with?('.')
        end.to_set
    end

    def filenames_in_database
      db.execute(
        "SELECT DISTINCT filename FROM songs"
      ).to_set
    end

    def filenames_missing_in_database
      filenames_in_music_transcription_dir - filenames_in_database
    end

    def init_db_schema
      db.execute(
        "CREATE TABLE IF NOT EXISTS songs(" \
        "name VARCHAR(255)," \
        "filename VARCHAR(255)," \
        "page_index INTEGER" \
        ")"
      )
    end
  end
end
