/* xnoise-tag-album-editor.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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
 *     Jörn Magens
 */


using Gtk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.TagAccess;



private class Xnoise.TagAlbumEditor : GLib.Object {
    private unowned Xnoise.Main xn;
    private Dialog dialog;
    private Gtk.Builder builder;
    private string new_content_name = "";
    private string new_artist_name = "";
    private uint new_year = 0;
    private string new_genre = "";
    private bool new_is_compilation = false;
    private unowned MusicBrowserModel mbm = null;
    private Label infolabel;
    private Entry year_entry;
    private Entry artist_entry;
    private Entry genre_entry;
    private Image albumimage;
    private CheckButton checkb_comp;
    
    private Entry entry;
    private HashTable<ItemType,Item?>? restrictions;
    private Item? item;
    
    public signal void sign_finish();

    public TagAlbumEditor(Item _item, HashTable<ItemType,Item?>? restrictions = null) {
        this.item = _item;
        this.restrictions = restrictions;
        xn = Main.instance;
        td_old = {};
        builder = new Gtk.Builder();
        setup_widgets();
        mbm = main_window.musicBr.mediabrowsermodel;
        mbm.notify["populating-model"].connect( () => {
            if(!global.media_import_in_progress && !mbm.populating_model)
                infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");;
        });
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress && !mbm.populating_model)
                infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");;
        });
        
        fill_entries();
        dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        dialog.show_all();
    }
    
    private void fill_entries() {
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.query_trackdata_job);
        job.item = item;
        db_worker.push_job(job);
    }

    private TrackData[] td_old;
    
    private bool query_trackdata_job(Worker.Job job) {
        // callback for query in other thread
        td_old = item_converter.to_trackdata(this.item, global.searchtext, restrictions);
        //foreach(var tdx in td_old)
        //    print("tit: %s\n", tdx.title);
        assert(td_old != null && td_old[0] != null);
        TrackData td = td_old[0];
        switch(item.type) {
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                Idle.add( () => {
                    // put data to entry
                    Gdk.Pixbuf? art = null;
                    //print("AAA td.artist: %s\n", td.artist);
                    File? f = get_albumimage_for_artistalbum(td.artist, td.album, "extralarge");
                    if(f != null)
                        art = AlbumArtView.icon_cache.get_image(f.get_path());
                    Gdk.Pixbuf? xicon = null;
                    if(art != null) {
                        albumimage.pixbuf = art;
                    }
                    else {
                        unowned Gtk.IconTheme theme = IconTheme.get_default();
                        if(theme.has_icon("xnoise")) 
                            xicon = theme.load_icon("xnoise", 64, IconLookupFlags.USE_BUILTIN);
                        albumimage.pixbuf = xicon;
                    }
                    entry.text         = td.album;
                    artist_entry.text  = td.albumartist;//(td.is_compilation ? VARIOUS_ARTISTS : td.artist);
                    year_entry.text    = (td.year > 0 ? td.year.to_string() : "");
                    genre_entry.text   = (td.genre != null ? td.genre : "");
//                    checkb_comp.notify["active"].connect( () => {
//                        if(checkb_comp.active) {
//                            artist_entry.text = VARIOUS_ARTISTS;
//                            artist_entry.set_sensitive(false);
//                        }
//                        else {
//                            artist_entry.text = td_old[0].artist;
//                            artist_entry.set_sensitive(true);
//                        }
//                    });
                    checkb_comp.active = td.is_compilation;
                    return false;
                });
                break;
            default:
                Idle.add( () => {
                    sign_finish();
                    return false;
                });
                break;
        }
        return false;
    }

    private void setup_widgets() {
        try {
            dialog = new Dialog();
            
            dialog.set_modal(true);
            dialog.set_transient_for(main_window);
            
            builder.add_from_file(Config.XN_UIDIR + "metadata_album.ui");
            
            var mainvbox           = builder.get_object("vbox1")           as Gtk.Box;
            var okbutton           = builder.get_object("okbutton")        as Gtk.Button;
            var cancelbutton       = builder.get_object("cancelbutton")    as Gtk.Button;
            entry                  = builder.get_object("entry1")          as Gtk.Entry;
            artist_entry           = builder.get_object("artist_entry")    as Gtk.Entry;
            checkb_comp            = builder.get_object("checkbutton1")    as Gtk.CheckButton;
            year_entry             = builder.get_object("year_entry")      as Gtk.Entry;
            genre_entry            = builder.get_object("genre_entry")     as Gtk.Entry;
            infolabel              = builder.get_object("label5")          as Gtk.Label;
            infolabel.label = 
            _("With this dialog you can change the metatags in the according files. \nHandle with care!");
            var explainer_label    = builder.get_object("explainer_label") as Gtk.Label;
            var content_label      = builder.get_object("content_label")   as Gtk.Label;
            var artist_label       = builder.get_object("artist_label")    as Gtk.Label;
            var year_label         = builder.get_object("year_label")      as Gtk.Label;
            var genre_label        = builder.get_object("genre_label")     as Gtk.Label;
            albumimage             = builder.get_object("albumimage")      as Gtk.Image;
            ((Gtk.Box)this.dialog.get_content_area()).add(mainvbox);
            okbutton.clicked.connect(on_ok_button_clicked);
            cancelbutton.clicked.connect(on_cancel_button_clicked);
            this.dialog.set_title(_("Album data"));
            switch(item.type) {
                case ItemType.COLLECTION_CONTAINER_ALBUM:
                    explainer_label.label =  _("Please enter new album data.");
                    artist_label.label    =  _("Album Artist:");
                    content_label.label   =  _("Album:");
                    year_label.label      =  _("Year:");
                    genre_label.label     =  _("Genre:");
                    break;
                default:
                    break;
            }
        }
        catch (GLib.Error e) {
            var msg = new Gtk.MessageDialog(null,
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.ERROR,
                                            Gtk.ButtonsType.CANCEL,
                                            "Failed to build dialog! %s\n",
                                            e.message);
            msg.run();
            return;
        }
    }
    
    private void on_ok_button_clicked(Gtk.Button sender) {
        if(mbm.populating_model) {
            infolabel.label = _("Please wait while filling media browser. Or cancel, if you do not want to wait.");
            return;
        }
        if(global.media_import_in_progress) {
            infolabel.label = _("Please wait while importing media. Or cancel, if you do not want to wait.");
            return;
        }
        infolabel.label = EMPTYSTRING;
        switch(item.type) {
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                do_album_rename();
                break;
            default:
                break;
        }
        Idle.add( () => {
            this.dialog.destroy();
            return false;
        });
    }
    
    private void do_album_rename() {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_tags_job);
        if(entry.text == null || entry.text.strip() == EMPTYSTRING) {
            print("Warning: new album name is empty!\n");
            Idle.add( () => {
                this.dialog.destroy();
                return false;
            });
            return;
        }
        //print(" entry.text.strip() : %s\n",  entry.text.strip());
        new_content_name = entry.text.strip();
        new_artist_name = artist_entry.text.strip();
        if(year_entry.text.strip() != EMPTYSTRING)
            new_year = (uint)int.parse(year_entry.text.strip());
        new_genre = genre_entry.text.strip();
        new_is_compilation = checkb_comp.active;
        job.item = this.item;
        io_worker.push_job(job);
    }

    private bool update_tags_job(Worker.Job tag_job) {
        if(tag_job.item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
            var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_filetags_job);
            job.track_dat = td_old;//item_converter.to_trackdata(tag_job.item, global.searchtext);
            if(job.track_dat == null)
                return false;
            job.item = tag_job.item;
            foreach(unowned TrackData td in job.track_dat) {
                td.albumartist    = new_artist_name;//(string)tag_job.get_arg("new_content_name");//
                td.album          = new_content_name;//(string)tag_job.get_arg("new_content_name");//
                td.year           = new_year;//(uint)  tag_job.get_arg("new_year");//
                td.genre          = new_genre; //(string)tag_job.get_arg("new_genre");//
                td.is_compilation = new_is_compilation;// (bool)  tag_job.get_arg("new_is_compilation");
            }
            global.in_tag_rename = true;
            io_worker.push_job(job);
        }
        return false;
    }

    private bool update_filetags_job(Worker.Job tag_job) {
        string[] paths = {};
        for(int i = 0; i < tag_job.track_dat.length; i++) {
            File f = File.new_for_uri(tag_job.track_dat[i].item.uri);
            if(!f.query_exists(null))
                continue;
            bool ret = false;
            var tw = new TagWriter();
            ret = tw.write_tag(f, tag_job.track_dat[i], false);
            
            if(ret) {
                paths += f.get_path();
            }
            else {
                print("No success for path : %s !!!\n", f.get_path());
            }
        }
        media_importer.reimport_media_files(paths);
        
        var fin_job = new Worker.Job(Worker.ExecutionType.ONCE, this.finish_job);
        db_worker.push_job(fin_job);
        return false;
    }
    
    private bool finish_job(Worker.Job job) {
        Timeout.add(200, () => {
            main_window.musicBr.mediabrowsermodel.filter();
            main_window.album_art_view.icons_model.filter();
            global.in_tag_rename = false;
            return false;
        });
        Timeout.add(300, () => {
            this.sign_finish();
            return false;
        });
        return false;
    }

    private void on_cancel_button_clicked(Gtk.Button sender) {
        Idle.add( () => {
            this.dialog.destroy();
            this.sign_finish();
            return false;
        });
    }
}

