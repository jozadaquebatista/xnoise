/* ubuntuone.vala
 *
 * Copyright (C) 2012  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */


using Xnoise;
using Xnoise.PluginModule;

using U1;


//Ubuntu One integration for Xnoise.
public class UbuntuOnePlugin : GLib.Object, IPlugin {
    public Main xn { get; set; }
    
    private uint owner_id;
    private unowned PluginModule.Container _owner;
    private U1MusicStoreWidget music_store_widget;

    construct {
        print("construct UbuntuOne plugin\n");
        this.music_store_widget = new U1MusicStoreWidget(this);
    }

    public PluginModule.Container owner {
        get {
            return _owner;
        }
        set {
            _owner = value;
        }
    }
    
    public string name { 
        get {
            return "ubuntuone_music_store";
        } 
    }

    public bool init() {
//        this.music_store_widget.activate(this.object);
        
        owner.sign_deactivated.connect(clean_up);
        return true;
    }
    
    public void uninit() {
        clean_up();
    }

    private void clean_up() {
//        music_store_widget.deactivate(this);
    }

    public Gtk.Widget? get_settings_widget() {
        return null;
    }

    public bool has_settings_widget() {
        return false;
    }
//    private void _locations_changed(*args, **kwargs) {
//        //Handle the locations setting being changed.
//        libraries = this.rdbconf.get_strv('locations')
//        library_uri = Gio.File.new_for_path(UbuntuOneUI.MusicStore.get_library_location()).get_uri()
//        if library_uri not in libraries:
//            libraries.append(library_uri)
//            this.rdbconf.set_strv('locations', libraries)
//        # Remove the non-uri path if it exists
//        if UbuntuOneUI.MusicStore.get_library_location() in libraries:
//            libraries.remove(UbuntuOneUI.MusicStore.get_library_location())
//            this.rdbconf.set_strv('locations', libraries)
//        # Remove the unescaped uri path if it exists
//        unescaped_path = u'file://{0}'.format(UbuntuOneUI.MusicStore.get_library_location())
//        if unescaped_path in libraries:
//            libraries.remove(unescaped_path)
//            this.rdbconf.set_strv('locations', libraries)
//    }
}


/*
public class U1EntryType(RB.RhythmDBEntryType) {
    //Entry type for the Ubuntu One Music Store source.

    public U1EntryType() {
//        RB.RhythmDBEntryType.__init__(name='ubuntuone')
    }

    public void do_can_sync_metadata(entry) {
        //Not a real source, so we can't sync metadata.
        return false;
    }

    public void do_sync_metadata(entry, changes) {
        //Do nothing.
        return;
    }
}


//The Ubuntu One Music Store.
public class U1MusicStoreWidget : GLib.Object {
    private UbuntuOnePlugin plugin;
    private U1EntryType entry_type;
    private U1Source source;
    
    public U1MusicStoreWidget(UbuntuOnePlugin plugin) {
        this.plugin = plugin
//        this.db = null;
//        this.shell = null;
        this.source = null;
        this.entry_type = new U1EntryType();
    }

    public void activate(shell) {
            //Plugin startup.
        this.db = shell.get_property("db");
        group = RB.DisplayPageGroup.get_by_id("stores");

        icon = Gtk.IconTheme.get_default().load_icon("ubuntuone", 24, 0);

        this.db.register_entry_type(this.entry_type);

        this.source = new U1Source(shell=shell,
                                  entry_type=this.entry_type,
                                  pixbuf=icon,
                                  plugin=this.plugin);
        shell.register_entry_type_for_source(this.source, this.entry_type);
        shell.append_display_page(this.source, group);

//        this.shell = shell;
//        this.source.connect("preview-mp3", this.play_preview_mp3)
//        this.source.connect("play-library", this.play_library)
//        this.source.connect("download-finished", this.download_finished)
//        this.source.connect("url-loaded", this.url_loaded)

//        this.source.props.query_model = RB.RhythmDBQueryModel.new_empty(
//            this.db)
    }

    public void deactivate(shell) {
        //Plugin shutdown.
        // remove source
        this.source.delete_thyself()
        // delete held references
        del this.db
        del this.source
        del this.shell
    }

    public void url_loaded(source, url) {
        //A URL is loaded in the plugin
        if urlparse.urlparse(url)[2] == "https":
            pass
        else:
            pass
    }

    private void _udf_path_to_library_uri(path) {
        //Build a URI from the path for the song in the library.
        if path.startswith(UbuntuOneUI.MusicStore.get_library_location()):
            library_path = path
        else:
            subpath = path
            if subpath.startswith("/"):
                subpath = subpath[1:]
            library_path = os.path.join(UbuntuOneUI.MusicStore.get_library_location(), subpath)
        // convert path to URI. Don't use urllib for this; Python and
        // glib escape URLs differently. gio does it the glib way.
        return Gio.File.new_for_path(library_path).get_uri()
    }

    public void download_finished(source, path) {
        //A file is finished downloading
        library_uri = this._udf_path_to_library_uri(path)
        // Import the URI
        if not this.db.entry_lookup_by_location(library_uri):
            this.db.add_uri(library_uri)
    }

    public void play_library(source, path) {
        //Switch to and start playing a song from the library
        uri = this._udf_path_to_library_uri(path)
        entry = this.db.entry_lookup_by_location(uri)
        if not entry:
            print "couldn't find entry", uri
            return
        libsrc = this.shell.props.library_source
        artist_view, album_view = libsrc.get_property_views()[0:2]
        song_view = libsrc.get_entry_view()
        artist = entry.get_string(RB.RhythmDBPropType.ARTIST)
        album = entry.get_string(RB.RhythmDBPropType.ALBUM)
        this.shell.props.display_page_tree.select(libsrc)
        artist_view.set_selection([artist])
        album_view.set_selection([album])
        song_view.scroll_to_entry(entry)
        player = this.shell.get_property('shell-player')
        player.stop()
        player.play_entry(entry, libsrc)
    }

    public void play_preview_mp3(source, url, title) {
        //Play a passed mp3; signal handler for preview-mp3 signal.
        // create an entry, don't save it, and play it
        entry = RB.RhythmDBEntry.new(this.db, this.entry_type, url)
        this.db.entry_set(entry, RB.RhythmDBPropType.TITLE, title)
        player = this.shell.get_property('shell-player')
        player.stop()
        player.play_entry(entry, this.source)
    }
}


//A Rhythmbox source widget for the U1 Music Store.
public class U1Source() : RB.Source {
    
    public GLib.GObject plugin { get; construct; }
    
    // we have the preview-mp3 signal; we receive it from the widget, and
    // re-emit it so that the plugin gets it, because the plugin actually
    // plays the mp3
    public signal void preview_mp3(string url, string title);
    public signal void play_library(string path);
    public signal void download_finished(string path);
    public signal void url_loaded(string url);
    
    public U1Source() {
        RB.Source.__init__(name=_("Ubuntu One"))
        this.browser = UbuntuOneUI.MusicStore(); //MUSIC_STORE_WIDGET
        this.__activated = false
        this.__plugin = null
        this.add_music_store_widget()
    }

    public void do_impl_activate() {
        //Source startup.
        if this.__activated:
            return
        this.__activated = true
        RB.Source.do_impl_activate(self)
    }

    public void do_impl_want_uri(uri) {
        //I want to handle u1ms URLs
        if uri.startswith("u1ms://"):
            return 100
        return 0
    }

    public void do_impl_add_uri(string uri, 
                                string title,
                                string genre,
                                callback=null,
                                callback_data=null,
                                destroy_data=null) {
                                
        //Handle a u1ms URL
        if not uri.startswith("u1ms://")
            return;
        uri_to_use = uri.replace("u1ms://", "http://")
        shell = this.get_property("shell")
        shell.props.display_page_tree.select(self)
        this.browser.load_store_link(uri_to_use)
        if callback is not null:
            callback(callback_data)
            if destroy_data is not null:
                destroy_data(callback_data)
    }

    public void add_music_store_widget() {
        //Display the music store widget in Rhythmbox.
        if this.browser.get_property('parent') is null:
            this.add(this.browser)
        else:
            this.browser.reparent(self)
        this.browser.show()
        this.show()
        this.browser.set_property("visible", true)
//        this.browser.connect("preview-mp3",
//                             this.re_emit_preview)
//        this.browser.connect("play-library",
//                             this.re_emit_playlibrary)
//        this.browser.connect("download-finished",
//                             this.re_emit_downloadfinished)
//        this.browser.connect("url-loaded",
//                             this.re_emit_urlloaded)
    }

//    public void do_impl_can_pause() {
//        //Implementation can pause.
//        return true  // so we can pause, else we segfault
//    }

//    private void re_emit_preview(widget, url, title) {
//        //Handle the preview-mp3 signal and re-emit it.
//        this.preview_mp3(url, title);
//    }

//    private void re_emit_playlibrary(widget, path) {
//        //Handle the play-library signal and re-emit it.
//        this.play_library(path);
//    }

//    private void re_emit_downloadfinished(widget, path) {
//        //Handle the download-finished signal and re-emit it.
//        this.download_finished(path);
//    }

//    private void re_emit_urlloaded(widget, url) {
//        //Handle the url-loaded signal and re-emit it.
//        this.url_loaded(url);
//    }
}
*/
