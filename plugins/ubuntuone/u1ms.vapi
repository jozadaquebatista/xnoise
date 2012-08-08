[CCode (lower_case_cprefix = "u1_")]
namespace U1 {
    [CCode (cheader_filename = "libubuntuoneui-3.0/u1-music-store.h", cname = "U1MusicStore", type_id = "u1_music_store_get_type ()")]
    public class MusicStore : Gtk.VBox {
        [CCode (has_construct_function = false)]
        public MusicStore ();
        public signal void preview_mp3 (string url, string title);
        public signal void play_library (string path);
        public signal void url_loaded (string url);
        public signal void download_finished (string path);
        public unowned string get_library_location ();
        public void load_store_link (string url);
    }
}

