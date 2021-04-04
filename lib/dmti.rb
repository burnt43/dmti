# TODO: Add command line options.
# 1. For song only mode
# 2. Blow up the database on startup (for testing)
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

    # TODO: I don't think this works correctly.
    def filenames_missing_in_database
      filenames_in_music_transcription_dir - filenames_in_database
    end

    def songs_in_db
      db.execute("SELECT * FROM songs ORDER BY name ASC")
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

    # Insert record into the song table.
    def create_song_mapping!(attrs)
      query = StringIO.new.tap do |s|
        s.print('INSERT INTO songs ')
        s.print('(name, filename, page_index) ')
        s.print('VALUES (')
        s.print("\"#{attrs[:name]}\",")
        s.print("\"#{attrs[:filename]}\",")
        s.print("#{attrs[:page_index]}")
        s.print(');')
      end.string

      db.execute(query)
    end
  end
end
