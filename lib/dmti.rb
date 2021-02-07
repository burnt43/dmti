module Dmti
  class << self
    def db
      @db ||= SQLite3::Database.new(Dmti::Config.database_pathname.to_s)
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
