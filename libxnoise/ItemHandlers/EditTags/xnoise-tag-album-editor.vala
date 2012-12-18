/* xnoise-tag-album-editor.vala
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
    private string? new_content_name = null;
    private uint new_year = 0;
    private string? new_genre = null;
    private unowned MusicBrowserModel mbm = null;
    private Label infolabel;
    private Entry year_entry;
    private Entry genre_entry;
    private Image albumimage;
    
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
                infolabel.label = EMPTYSTRING;
        });
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress && !mbm.populating_model)
                infolabel.label = EMPTYSTRING;
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
        assert(td_old != null && td_old[0] != null);
        TrackData td = td_old[0];
        switch(item.type) {
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                Idle.add( () => {
                    // put data to entry
                    Gdk.Pixbuf? art = null;
                    File? f = get_albumimage_for_artistalbum(td.artist, td.album, "extralarge");
                    if(f != null)
                        art = AlbumArtView.icon_cache.get_image(f.get_path());
                    Gdk.Pixbuf? xicon = null;
                    unowned Gtk.IconTheme theme = IconTheme.get_default();
                    if(art != null) {
                        albumimage.pixbuf = art;
                    }
                    else {
                        if(theme.has_icon("xnoise")) 
                            xicon = theme.load_icon("xnoise", 48, IconLookupFlags.USE_BUILTIN);
                        albumimage.pixbuf = xicon;
                    }
                    entry.text  = td.album;
                    year_entry.text = (td.year > 0 ? td.year.to_string() : "");
                    genre_entry.text = (td.genre != null ? td.genre : "");
                    albumimage = new Image.from_stock(Stock.MEDIA_PLAY, IconSize.LARGE_TOOLBAR);
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
            year_entry             = builder.get_object("year_entry")      as Gtk.Entry;
            genre_entry            = builder.get_object("genre_entry")     as Gtk.Entry;
            infolabel              = builder.get_object("label5")          as Gtk.Label;
            var explainer_label    = builder.get_object("explainer_label") as Gtk.Label;
            var content_label      = builder.get_object("content_label")   as Gtk.Label;
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
                                            "Failed to build dialog! %s\n".printf(e.message));
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
        if(entry.text != null && entry.text.strip() != EMPTYSTRING) {
            new_content_name = entry.text.strip();
            new_year  = (uint)int.parse(year_entry.text.strip());
            new_genre = genre_entry.text.strip();
            //print("new_year val : %u\n", new_year);
        }
        // TODO: UTF-8 validation
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
        job.set_arg("new_content_name", new_content_name);
        job.set_arg("new_year", new_year);
        job.set_arg("new_genre", new_genre);
        job.item = this.item;
        db_worker.push_job(job);
    }


    private bool update_tags_job(Worker.Job tag_job) {
        if(tag_job.item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
            var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_filetags_job);
            job.track_dat = item_converter.to_trackdata(tag_job.item, global.searchtext);
            if(job.track_dat == null)
                return false;
            job.item = tag_job.item;
            foreach(TrackData td in job.track_dat) {
                td.album = new_content_name;
                td.year  = new_year;
                td.genre = new_genre;
            }
            io_worker.push_job(job);
        }
        return false;
    }

    private bool update_filetags_job(Worker.Job job) {
        //print("job.track_dat len : %d\n", job.track_dat.length);
        if(job.track_dat.length > 0) {
            var bjob = new Worker.Job(Worker.ExecutionType.ONCE, this.begin_job);
            db_worker.push_job(bjob);
        }
        for(int i = 0; i<job.track_dat.length; i++) {
            File f = File.new_for_uri(job.track_dat[i].item.uri);
            if(!f.query_exists(null))
                continue;
            var tw = new TagWriter();
            bool ret = false;
            if(job.item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
                ret =  tw.write_album(f, job.track_dat[i].album);
                ret |= tw.write_year (f, job.track_dat[i].year );
                ret |= tw.write_genre(f, job.track_dat[i].genre);
            }
            if(ret) {
                var dbjob = new Worker.Job(Worker.ExecutionType.ONCE, this.update_db_job);
                TrackData td = job.track_dat[i];
                dbjob.set_arg("td", td);
                dbjob.item = job.item;
                db_worker.push_job(dbjob);
            }
        }
        var fin_job = new Worker.Job(Worker.ExecutionType.ONCE, this.finish_job);
        
        db_worker.push_job(fin_job);
        return false;
    }
    
    private bool begin_job(Worker.Job job) {
        db_writer.begin_transaction();
        return false;
    }
    
    private bool finish_job(Worker.Job job) {
        db_writer.commit_transaction();
        Timeout.add(200, () => {
            main_window.musicBr.mediabrowsermodel.filter();
            return false;
        });
        Timeout.add(300, () => {
            this.sign_finish();
            return false;
        });
        return false;
    }

    private bool update_db_job(Worker.Job job) {
        TrackData td = (TrackData)job.get_arg("td");
        media_importer.update_item_tag(ref job.item, ref td);
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

