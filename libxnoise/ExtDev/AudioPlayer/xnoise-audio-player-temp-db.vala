
using Sqlite;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


public class Xnoise.ExtDev.AudioPlayerTempDb : Xnoise.DataSource {
    private string CONVERTED_DB;

    // SQL
    private static const string STMT_CREATE_ARTISTS =
        "CREATE TABLE artists (id INTEGER PRIMARY KEY, name TEXT);";
    private static const string STMT_CREATE_ALBUMS =
        "CREATE TABLE albums (id INTEGER PRIMARY KEY, artist INTEGER, name TEXT, image TEXT);";
    private static const string STMT_CREATE_URIS =
        "CREATE TABLE uris (id INTEGER PRIMARY KEY, name TEXT, type INTEGER, transformed TEXT);";
    private static const string STMT_CREATE_GENRES =
        "CREATE TABLE genres (id integer primary key, name TEXT);";
    private static const string STMT_CREATE_ITEMS =
        "CREATE TABLE items (id INTEGER PRIMARY KEY, tracknumber INTEGER, artist INTEGER, album INTEGER, title TEXT, genre INTEGER, year INTEGER, uri INTEGER, mediatype INTEGER, length INTEGER, bitrate INTEGER, usertags TEXT, playcount INTEGER, rating INTEGER, lastplayTime DATETIME, addTimeUnix INTEGER, mimetype TEXT);";
    private static const string STMT_BEGIN =
        "BEGIN";
    private static const string STMT_COMMIT =
        "COMMIT";
    private static const string STMT_CHECK_TRACK_EXISTS =
        "SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
    private static const string STMT_INSERT_ARTIST =
        "INSERT INTO artists (name) VALUES (?)";
    private static const string STMT_INSERT_ALBUM =
        "INSERT INTO albums (artist, name) VALUES (?, ?)";
    private static const string STMT_GET_URI_ID =
        "SELECT id FROM uris WHERE utf8_lower(name) = ?";
    private static const string STMT_INSERT_URI =
        "INSERT INTO uris (name) VALUES (?)";
    private static const string STMT_GET_GENRE_ID =
        "SELECT id FROM genres WHERE utf8_lower(name) = ?";
    private static const string STMT_INSERT_GENRE =
        "INSERT INTO genres (name) VALUES (?)";
    private static const string STMT_GET_TITLE_ID =
        "SELECT id FROM items WHERE artist = ? AND album = ? AND utf8_lower(title) = ?";

    private Statement begin_statement;
    private Statement commit_statement;
    private Statement get_artist_id_statement;
    private Statement insert_artist_statement;
    private Statement get_album_id_statement;
    private Statement insert_album_statement;
    private Statement get_uri_id_statement;
    private Statement insert_uri_statement;
    private Statement get_genre_id_statement;
    private Statement insert_genre_statement;
    private Statement insert_title_statement;
    private Statement get_title_id_statement;

    private unowned Cancellable cancel;
    
    public AudioPlayerTempDb(Cancellable cancel) {
        uint32 number = Random.next_int();
        data_source_name = "Tempdb" + number.to_string();
        this.cancel = cancel;
        CONVERTED_DB = GLib.Path.build_filename(temp_folder(),
                                                "player" +
                                                    number.to_string() +
                                                    ".sqlite",
                                                null
        );
        
        if(cancel.is_cancelled())
            return;
        bool ret = create_target_db();
        assert(ret == true);
        
        prepare_target_statements();
    }
    
    ~AudioPlayerTempDb() {
        db = null;
        File f = File.new_for_path(CONVERTED_DB);
        try {
            f.delete();
        }
        catch(Error e) {
        }
    }

    private void prepare_target_statements() {
        db.create_function_v2("utf8_lower", 1, Sqlite.ANY, null, utf8_lower, null, null, null);
        db.create_collation("CUSTOM01", Sqlite.UTF8, compare_func);
        
        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_SEARCH, -1, out get_artists_with_search_stmt);
        this.db.prepare_v2(STMT_GET_ARTISTS, -1, out get_artists_with_search2_stmt);
        
        db.prepare_v2(STMT_BEGIN, -1, out this.begin_statement);
        db.prepare_v2(STMT_COMMIT, -1, out this.commit_statement);
        db.prepare_v2(STMT_GET_ARTIST_ID, -1, out this.get_artist_id_statement);
        db.prepare_v2(STMT_INSERT_ARTIST, -1, out this.insert_artist_statement);
        db.prepare_v2(STMT_GET_ALBUM_ID, -1, out this.get_album_id_statement);
        db.prepare_v2(STMT_INSERT_ALBUM, -1, out this.insert_album_statement);
        db.prepare_v2(STMT_GET_URI_ID, -1, out this.get_uri_id_statement);
        db.prepare_v2(STMT_INSERT_URI, -1, out this.insert_uri_statement);
        db.prepare_v2(STMT_GET_GENRE_ID, -1, out this.get_genre_id_statement);
        db.prepare_v2(STMT_INSERT_GENRE, -1, out this.insert_genre_statement);
        db.prepare_v2(STMT_INSERT_TITLE, -1, out this.insert_title_statement);
        db.prepare_v2(STMT_GET_TITLE_ID, -1, out this.get_title_id_statement);
    }

//    public void move_data() {
//        this.begin_transaction();
//        get_source_tracks();
//        this.commit_transaction();
//        return;
//    }

    private bool begin_stmt_used = false;
    
    public void begin_transaction() {
        exec_prepared_stmt(begin_statement);
        begin_stmt_used = true;
    }

    public void commit_transaction() {
        if(begin_stmt_used != true)
            return;
            
        exec_prepared_stmt(commit_statement);
        begin_stmt_used = false;
    }

    private bool exec_prepared_stmt(Statement stmt) {
        stmt.reset();
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return false;
        }
        return true;
    }

//    private static const string STMT_GET_TRACKS =
//        "SELECT DISTINCT s.desc, s.mp3, s.number, al.artist, s.albumname, g.genre, al.launchdate, s.duration, al.sku FROM albums al, songs s, genres g WHERE s.albumname = al.albumname AND g.albumname = al.albumname";
    private static const string STMT_INSERT_TITLE =
        "INSERT INTO items (tracknumber, artist, album, title, genre, year, uri, mediatype, length, bitrate, mimetype) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    private int count = 0;
    
    public void insert_tracks(ref TrackData[] tda) {
        count = 0;
        
        foreach(TrackData td in tda) {
            if(cancel.is_cancelled())
                return;
            // INSERT
            int32 artist_id = handle_artist(ref td.artist);
            if(artist_id == -1) {
                print("Error importing artist for %s : '%s' ! \n", td.item.uri, td.artist);
                return;
            }
            int32 album_id = handle_album(ref artist_id, ref td.album);
            if(album_id == -1) {
                print("Error importing album for %s : '%s' ! \n", td.item.uri, td.album);
                return;
            }
            int uri_id = handle_uri(td.item.uri);
            if(uri_id == -1) {
                //print("Error importing uri for %s : '%s' ! \n", uri, uri);
                return;
            }
            int genre_id = handle_genre(ref td.genre);
            if(genre_id == -1) {
                print("Error importing genre for %s : '%s' ! \n", td.item.uri, td.genre);
                return;
            }
            //print("insert_title td.item.type %s\n", td.item.type.to_string());
            insert_title_statement.reset();
            if(insert_title_statement.bind_int (1,  (int)td.tracknumber) != Sqlite.OK ||
               insert_title_statement.bind_int (2,  artist_id)      != Sqlite.OK ||
               insert_title_statement.bind_int (3,  album_id)       != Sqlite.OK ||
               insert_title_statement.bind_text(4,  td.title)       != Sqlite.OK ||
               insert_title_statement.bind_int (5,  genre_id)       != Sqlite.OK ||
               insert_title_statement.bind_int (6,  (int)td.year)        != Sqlite.OK ||
               insert_title_statement.bind_int (7,  uri_id)         != Sqlite.OK ||
               insert_title_statement.bind_int (8,  td.item.type)   != Sqlite.OK ||
               insert_title_statement.bind_int (9,  td.length)      != Sqlite.OK
               ) {
                this.db_error();
                return;
            }
            if(insert_title_statement.step() != Sqlite.DONE) {
                this.db_error();
                return;
            }
            count++;
            if(count % 200 == 0) {
                int cz = count;
                Idle.add(() => {
                    progress(cz);
                    return false;
                });
            }
        }
        Idle.add(() => {
            if(cancel.is_cancelled())
                return false;
            progress(count);
            return false;
        });
    }

    public signal void progress(int cnt);

    private bool create_target_db() {
        if(cancel.is_cancelled())
            return false;
        setup_target_handle();
        if(db == null)
            return false;
        //use a db structure similar to xnoise's
        if(!exec_stmnt_string(STMT_CREATE_ARTISTS)        ) { return false; }
        if(!exec_stmnt_string(STMT_CREATE_ALBUMS)         ) { return false; }
        if(!exec_stmnt_string(STMT_CREATE_URIS)           ) { return false; }
        if(!exec_stmnt_string(STMT_CREATE_ITEMS)          ) { return false; }
        if(!exec_stmnt_string(STMT_CREATE_GENRES)         ) { return false; }
        
        return true;
    }

    private bool exec_stmnt_string(string statement) {
        string errormsg;
        if(db.exec(statement, null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s", errormsg);
            return false;
        }
        return true;
    }
    
    private void setup_target_handle() {
        File tf = File.new_for_path(CONVERTED_DB);
        if(tf.query_exists(null)) {
            try {
                tf.delete();
            }
            catch(Error e) {
                print("##2%s\n", e.message);
            }
        }
        Sqlite.Database.open_v2(tf.get_path(),
                                out db,
                                Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE,
                                null
                                );
    }

    private static void utf8_lower(Sqlite.Context context,
                                   [CCode (array_length_pos = 1.1)] Sqlite.Value[] values) {
        context.result_text(values[0].to_text().down());
    }
    
    private static int compare_func(int alen, void* a, int blen, void* b) {
        return GLib.strcmp(((string)a).collate_key(alen), ((string)b).collate_key(blen));
    }
    
    private Sqlite.Database db;

//    private string dbFileName() {
//        return UNZIPPED_DB;//GLib.Path.build_filename("tmp", "xnoise_magnatune_db", null);
//    }

    private static const string STMT_GET_ITEM_DAT = 
       "SELECT id,artist,album FROM items WHERE uri=?";
    
    private static const string STMT_GET_TRACK_CNT_FOR_ARTIST = 
       "SELECT COUNT(id) FROM items WHERE artist=(SELECT artist FROM items WHERE items.id=?)";

    private static const string STMT_GET_TRACK_CNT_FOR_ALBUM = 
       "SELECT COUNT(id) FROM items WHERE album=(SELECT album FROM items WHERE items.id=?)";
    
    public void remove_uri(string uri) {
        Statement stmt;
        string errormsg;
        
        this.get_uri_id_statement.reset();
        if(this.get_uri_id_statement.bind_text(1, uri.strip().down())!= Sqlite.OK ) {
            return;
        }
        int32 uri_id = -1;
        if(this.get_uri_id_statement.step() == Sqlite.ROW) {
            uri_id = this.get_uri_id_statement.column_int(0);
        }
        else {
            return;
        }
        
        db.prepare_v2(STMT_GET_ITEM_DAT, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        
        int32 item_id   = -1;
        int32 artist_id = -1;
        int32 album_id  = -1;
        
        if(stmt.step() == Sqlite.ROW) {
            item_id     = stmt.column_int(0);
            artist_id   = stmt.column_int(1);
            album_id    = stmt.column_int(2);
        }
        else {
            return;
        }
        
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ARTIST, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        bool more_tracks_from_same_artist = true;
        if(stmt.step() == Sqlite.ROW) {
            more_tracks_from_same_artist = stmt.column_int(0) > 1;
        }
        else {
            return;
        }
        
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ALBUM, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        bool more_tracks_from_same_album = true;
        if(stmt.step() == Sqlite.ROW) {
            more_tracks_from_same_album = stmt.column_int(0) > 1;
        }
        else {
            return;
        }
        
        if(!more_tracks_from_same_artist) {
            if(db.exec("DELETE FROM artists WHERE id=%d;".printf(artist_id), null, out errormsg)!= Sqlite.OK) {
                stderr.printf("exec_stmnt_string error: %s\n", errormsg);
            }
        }
        if(!more_tracks_from_same_album) {
            if(db.exec("DELETE FROM albums WHERE id=%d;".printf(album_id), null, out errormsg)!= Sqlite.OK) {
                stderr.printf("exec_stmnt_string error: %s\n", errormsg);
            }
        }
        if(db.exec("DELETE FROM items WHERE id=%d;".printf(item_id), null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s\n", errormsg);
        }
        if(db.exec("DELETE FROM uris WHERE id=%d;".printf(uri_id), null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s\n", errormsg);
        }
    }

    private static const string STMT_GET_GET_ITEM_ID = 
        "SELECT id FROM items WHERE artist = ? AND album = ? AND title = ?";
    
    private static const string STMT_GET_ITEM_ID =
        "SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.id = ?";
    
    private static const string STMT_GET_ARTIST_MAX_ID =
        "SELECT MAX(id) FROM artists";
    private static const string STMT_GET_ARTIST_ID =
        "SELECT id FROM artists WHERE utf8_lower(name) = ?";
    private static const string STMT_UPDATE_ARTIST_NAME = 
        "UPDATE artists SET name=? WHERE id=?";
    private int handle_artist(ref string artist, bool update_artist = false) {
        // return id for artist
        get_artist_id_statement.reset();
        if(get_artist_id_statement.bind_text(1, (artist != null ? artist.down() : EMPTYSTRING)) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_artist_id_statement.step() == Sqlite.ROW)
            return get_artist_id_statement.column_int(0);
        
        insert_artist_statement.reset();
        if(insert_artist_statement.bind_text(1, artist) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_artist_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        Statement stmt;
        db.prepare_v2(STMT_GET_ARTIST_MAX_ID, -1, out stmt);
        if(stmt.step() == Sqlite.ROW)
            return stmt.column_int(0);
        else
            return -1;
    }

//    private static const string STMT_INS_ALBUM =
//        "INSERT INTO albums (artist, name) VALUES ((SELECT id FROM artists ar WHERE utf8_lower(ar.name) = ?), ?)";
    private static const string STMT_GET_ALBUM_ID =
        "SELECT id FROM albums WHERE artist = ? AND utf8_lower(name) = ?";
//    private static const string STMT_UPDATE_ALBUM_NAME = 
//        "UPDATE albums SET name=? WHERE id=?";
    private static const string STMT_GET_ALBUMS_MAX_ID =
        "SELECT MAX(id) FROM albums";

    private int handle_album(ref int artist_id, ref string album) {
        get_album_id_statement.reset();
        if(get_album_id_statement.bind_int (1, artist_id) != Sqlite.OK ||
           get_album_id_statement.bind_text(2, album != null ? album.down().strip() : EMPTYSTRING) != Sqlite.OK ) {
            this.db_error();
            return -1;
           }
        if(get_album_id_statement.step() == Sqlite.ROW)
            return get_album_id_statement.column_int(0);
        
        // Insert album
        insert_album_statement.reset();
        if(insert_album_statement.bind_int (1, artist_id) != Sqlite.OK ||
           insert_album_statement.bind_text(2, album) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_album_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        
        //Return id
        Statement stmt;
        db.prepare_v2(STMT_GET_ALBUMS_MAX_ID, -1, out stmt);
        if(stmt.step() == Sqlite.ROW)
            return stmt.column_int(0);
        else
            return -1;
    }

    private static const string STMT_GET_URI_MAX_ID =
        "SELECT MAX(id) FROM uris";
    
    private int handle_uri(string uri) {
        // Insert uri
//        get_uri_id_statement.reset();
//        if(get_uri_id_statement.bind_text(1, uri != null ? uri.down().strip() : EMPTYSTRING) != Sqlite.OK) {
//            this.db_error();
//            return -1;
//        }
//        if(get_uri_id_statement.step() == Sqlite.ROW)
//            return get_uri_id_statement.column_int(0);
        insert_uri_statement.reset();
        if(insert_uri_statement.bind_text(1, uri.strip()) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_uri_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        Statement stmt;
        db.prepare_v2(STMT_GET_URI_MAX_ID, -1, out stmt);
        if(stmt.step() == Sqlite.ROW)
            return stmt.column_int(0);
        else
            return -1;
    }

    private static const string STMT_GET_GENRE_MAX_ID =
        "SELECT MAX(id) FROM genres";

    private int handle_genre(ref string genre) {
//        int genre_id = -1;
        if((genre == null)||(genre.strip() == EMPTYSTRING)) return -2; //NO GENRE

        get_genre_id_statement.reset();
        if(get_genre_id_statement.bind_text(1, genre != null ? genre.down().strip() : EMPTYSTRING) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_genre_id_statement.step() == Sqlite.ROW)
            return get_genre_id_statement.column_int(0);
        // Insert genre
        insert_genre_statement.reset();
        if(insert_genre_statement.bind_text(1, genre.strip()) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_genre_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        // Return id key
        Statement stmt;
        db.prepare_v2(STMT_GET_GENRE_MAX_ID, -1, out stmt);
        if(stmt.step() == Sqlite.ROW)
            return stmt.column_int(0);
        else
            return -1;
    }

    private void db_error() {
        print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
    }

    private string data_source_name;
    public override unowned string get_datasource_name() {
        return data_source_name;
    }

    private static const string STMT_TRACKDATA_FOR_URI =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.length, t.mediatype, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND u.name = ?";

    public override bool get_trackdata_for_uri(ref string? uri, out TrackData val) {
        bool retval = false;
        val = new TrackData();
        if(uri == null)
            return retval;
        
        uint32 stamp = get_current_stamp(get_source_id());
        Statement stmt;
        this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, out stmt);
        bool found = false;
        stmt.reset();
        stmt.bind_text(1, uri);
        if(stmt.step() == Sqlite.ROW) {
            val.artist      = stmt.column_text(0);
            val.album       = stmt.column_text(1);
            val.title       = stmt.column_text(2);
            val.tracknumber = (uint)stmt.column_int(3);
            val.length      = stmt.column_int(4);
            val.item        = Item((ItemType)stmt.column_int(5), uri, stmt.column_int(6));
            val.item.source_id = get_source_id();
            val.item.stamp = stamp;
            val.genre       = stmt.column_text(7);
            val.year        = stmt.column_int(8);
            retval = true;
            found = true;
        }
        if(found == false) {
            stmt.reset();
            string turi = uri;
            stmt.bind_text(1, turi);
            if(stmt.step() == Sqlite.ROW) {
                val.artist      = stmt.column_text(0);
                val.album       = stmt.column_text(1);
                val.title       = stmt.column_text(2);
                val.tracknumber = (uint)stmt.column_int(3);
                val.length      = stmt.column_int(4);
                val.item        = Item((ItemType)stmt.column_int(5), turi, stmt.column_int(6));
                val.item.source_id = get_source_id();
                val.item.stamp = stamp;
                val.genre       = stmt.column_text(7);
                val.year        = stmt.column_int(8);
                retval = true;
            }
        }
        if((val.artist==EMPTYSTRING) | (val.artist==null)) {
            val.artist = UNKNOWN_ARTIST;
        }
        if((val.album== EMPTYSTRING) | (val.album== null)) {
            val.album = UNKNOWN_ALBUM;
        }
        if((val.genre== EMPTYSTRING) | (val.genre== null)) {
            val.genre = UNKNOWN_GENRE;
        }
        if((val.title== EMPTYSTRING) | (val.title== null)) {
            val.title = UNKNOWN_TITLE;
            File file = File.new_for_uri(uri);
            string fpath = file.get_path();
            string fileBasename = EMPTYSTRING;
            if(fpath!=null) fileBasename = GLib.Filename.display_basename(fpath);
            val.title = fileBasename;
        }
        return retval;
    }




    private static const string STMT_GET_ARTISTS_WITH_SEARCH =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND (utf8_lower(t.title) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(ar.name) LIKE ? OR utf8_lower(g.name) LIKE ?) ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";

    private static const string STMT_GET_ARTISTS =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t WHERE t.artist = ar.id ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";
    
    private Statement get_artists_with_search_stmt;
    private Statement get_artists_with_search2_stmt;
    
    public override Item[] get_artists(string searchtext = "",
                                       CollectionSortMode sort_mode,
                                       HashTable<ItemType,Item?>? items = null) {
        Item[] val = {};
        if(cancel.is_cancelled())
            return val;
        uint32 stamp = get_current_stamp(this.get_source_id());
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            get_artists_with_search_stmt.reset();
            if(get_artists_with_search_stmt.bind_text(1, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(2, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(3, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(4, st) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_artists_with_search_stmt.step() == Sqlite.ROW) {
                if(cancel.is_cancelled())
                    return val;
                Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, get_artists_with_search_stmt.column_int(0));
                i.text = get_artists_with_search_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stamp;
                val += i;
            }
        }
        else {
            get_artists_with_search2_stmt.reset();
            while(get_artists_with_search2_stmt.step() == Sqlite.ROW) {
                if(cancel.is_cancelled())
                    return val;
                Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, 
                              null, 
                              get_artists_with_search2_stmt.column_int(0)
                );
                i.text = get_artists_with_search2_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stamp;
                val += i;
            }
        }
        return (owned)val;
    }




    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g  WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_for_albumartist(string searchtext,
                                                          CollectionSortMode sort_mode,
                                                          HashTable<ItemType,Item?>? items) {
        Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUMARTIST);
        return_val_if_fail(artist != null && get_current_stamp(get_source_id()) == artist.stamp, null);
        
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, artist.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
            if((stmt.bind_int(1, artist.db_id)!=Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }        
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = artist.stamp;
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            val += td;
        }
        return (owned)val;
    }

    public override TrackData[]? get_trackdata_for_artist(string searchtext,
                                                          CollectionSortMode sort_mode,
                                                          HashTable<ItemType,Item?>? items) {
        return get_trackdata_for_albumartist(searchtext, sort_mode, items);
    }

    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?)";
    
    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
    
    public override Item? get_album_item_from_id(string searchtext, int32 id, uint32 stamp) {
        return null;
    }
    
    public override Item? get_albumartist_item_from_id(string searchtext, int32 id, uint32 stamp) {
        return_val_if_fail(get_current_stamp(get_source_id()) == stamp, null);
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        i.source_id = get_source_id();
        i.stamp = stamp;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID, -1, out stmt);
            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        if(stmt.step() == Sqlite.ROW) {
            i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, id);
            i.text = stmt.column_text(0);
            i.source_id = get_source_id();
            i.stamp = stamp;
        }
        return (owned)i;
    }

//    private static const string STMT_GET_SKU_BY_ALBUMID =
//        "SELECT DISTINCT al.sku FROM albums al WHERE al.id = ?";
//    
//    internal string? get_sku_for_album(int32 id) {
//        string? val = null;
//        Statement stmt;
//        this.db.prepare_v2(STMT_GET_SKU_BY_ALBUMID, -1, out stmt);
//        if((stmt.bind_int(1, id) != Sqlite.OK)) {
//            this.db_error();
//            return null;
//        }
//        if(stmt.step() == Sqlite.ROW) {
//            return stmt.column_text(0);
//        }
//        return val;
//    }
    
//    private static const string STMT_GET_SKU_BY_TITLEID =
//        "SELECT DISTINCT al.sku FROM items t, albums al WHERE t.album = al.id AND t.id = ?";
//    
//    internal string? get_sku_for_title(int32 id) {
//        string? val = null;
//        Statement stmt;
//        this.db.prepare_v2(STMT_GET_SKU_BY_TITLEID, -1, out stmt);
//        if((stmt.bind_int(1, id) != Sqlite.OK)) {
//            this.db_error();
//            return null;
//        }
//        if(stmt.step() == Sqlite.ROW) {
//            return stmt.column_text(0);
//        }
//        return val;
//    }
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_for_album(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items) {
        Item? album = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUM);
        return_val_if_fail(get_current_stamp(get_source_id()) == album.stamp, null);
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, album.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
            if((stmt.bind_int(1, album.db_id) != Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = album.stamp;
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_ALBUMS_WITH_SEARCH =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g WHERE ar.id = t.artist AND al.id = t.album AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ALBUMS =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al WHERE ar.id = al.artist AND ar.id = ? ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    public override Item[] get_albums(string searchtext,
                                      CollectionSortMode sort_mode,
                                      HashTable<ItemType,Item?>? items) {
        Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUMARTIST);
        return_val_if_fail(artist != null &&
                             get_current_stamp(this.get_source_id()) == artist.stamp,
                           null);
        Item[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_ALBUMS_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, artist.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
            if((stmt.bind_int(1, artist.db_id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
            i.text        = stmt.column_text(0);
            i.source_id   = get_source_id();
            i.stamp       = artist.stamp;
            val += i;
        }
        return (owned)val;
    }



    private static const string STMT_GET_TRACKDATA_BY_TITLEID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
        
    public override TrackData[] get_trackdata_for_item(string searchterm, Item? item) {
        return_val_if_fail(item != null && get_current_stamp(get_source_id()) == item.stamp, null);
        Statement stmt;
        TrackData[] tda = {};
        this.db.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
        
        if((stmt.bind_int(1, item.db_id)!=Sqlite.OK)) {
            this.db_error();
            return (owned)tda;
        }
        TrackData td = null; 
        if(stmt.step() == Sqlite.ROW) {
            td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = item.stamp;
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            tda += td;
        }
        return (owned)tda;
    }

//    private static const string STMT_STREAM_TD_FOR_ID =
//        "SELECT name, uri FROM streams WHERE id = ?";

    public override bool get_stream_trackdata_for_item(Item? item, out TrackData val) {
        return_val_if_fail(item != null && get_current_stamp(get_source_id()) == item.stamp, false);
        val = null;
        TrackData[] tda = get_trackdata_for_item(global.searchtext, item);
        
        if(tda == null || tda.length == 0)
            return false;
        
        val = tda[0];
        
        return true;
    }
    
    private static const string STMT_ALL_TRACKDATA =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY u.name ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 ASC, utf8_lower(al.name) COLLATE CUSTOM01 ASC, t.tracknumber ASC";
    
    public override TrackData[]? get_all_tracks(string searchtext) {
        Statement stmt;
        TrackData[] retv = {};
        string st = "%%%s%%".printf(searchtext);
        
        uint stamp = get_current_stamp(get_source_id());
        
        this.db.prepare_v2(STMT_ALL_TRACKDATA , -1, out stmt);
        if(stmt.bind_text(1, st) != Sqlite.OK ||
           stmt.bind_text(2, st) != Sqlite.OK ||
           stmt.bind_text(3, st) != Sqlite.OK) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData val = new TrackData();
            val.artist      = stmt.column_text(0);
            val.album       = stmt.column_text(1);
            val.title       = stmt.column_text(2);
            val.tracknumber = stmt.column_int(3);
            val.length      = stmt.column_int(6);
            val.item        = Item((ItemType)stmt.column_int(4), stmt.column_text(5), stmt.column_int(7));
            val.item.stamp = stamp;
            val.item.source_id = get_source_id();
            val.genre       = stmt.column_text(8);
            val.year        = stmt.column_int(9);
            if((val.artist==EMPTYSTRING) || (val.artist==null)) {
                val.artist = UNKNOWN_ARTIST;
            }
            if((val.album== EMPTYSTRING) || (val.album== null)) {
                val.album = UNKNOWN_ALBUM;
            }
            if((val.genre== EMPTYSTRING) || (val.genre== null)) {
                val.genre = UNKNOWN_GENRE;
            }
            if((val.title== EMPTYSTRING) || (val.title== null)) {
                val.title = UNKNOWN_TITLE;
                File file = File.new_for_uri(val.item.uri);
                string fileBasename;
                if(file != null)
                    fileBasename = GLib.Filename.display_basename(file.get_path());
                else
                    fileBasename = val.item.uri;
                val.title = fileBasename;
            }
            retv += val;
        }
        return (owned)retv;
    }
}

