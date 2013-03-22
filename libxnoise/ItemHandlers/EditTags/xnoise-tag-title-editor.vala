/* xnoise-tag-title-editor.vala
 *
 * Copyright (C) 2011 - 2013  Jörn Magens
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


private class Xnoise.TagTitleEditor : GLib.Object {
    private unowned Xnoise.Main xn;
    private Dialog dialog;
    private Gtk.Builder builder;
    private unowned MusicBrowserModel mbm = null;
    
    private Entry entry_artist;
    private Entry entry_albumartist;
    private Entry entry_album;
    private Entry entry_title;
    private CheckButton check_compilation;
    private SpinButton spinbutton_tracknumber;
    private SpinButton spinbutton_year;
    private SpinButton spinbutton_disk;
    private Entry entry_genre;
    private Entry entry_uri;
    private Item? item;
    
    public signal void sign_finish();

    public TagTitleEditor(Item _item) {
        item = _item;
        xn = Main.instance;
        builder = new Gtk.Builder();
        setup_widgets();
        mbm = main_window.musicBr.mediabrowsermodel;
        fill_entries();
        dialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        dialog.show_all();
    }
    
    private void fill_entries() {
        // read tags and put them to the entries; store current tags to be able to realize changes
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE_HIGH_PRIORITY, this.query_trackdata_job);
        job.item = item;
        db_worker.push_job(job);
    }

    private TrackData td_old = null;
    
    private bool query_trackdata_job(Worker.Job job) {
        // callback for query in other thread
        TrackData[] tmp = {};
        if(global.media_import_in_progress) {
            Idle.add( () => {
                this.dialog.destroy();
                return false;
            });
            return false;
        }
        tmp = item_converter.to_trackdata(item, global.searchtext);
        if(tmp == null || tmp.length == 0 || tmp[0] == null) {
            Idle.add( () => {
                this.dialog.destroy();
                return false;
            });
            return false;
        }
        
        TrackData td = tmp[0];
        
        td_old = copy_trackdata(td);
        
        Idle.add( () => {
            // put data to entry
            entry_artist.text      = td.artist;
            entry_albumartist.text = (td.albumartist == "*" ? EMPTYSTRING : td.albumartist);
            entry_album.text       = td.album;
            entry_title.text       = td.title;
            entry_genre.text       = td.genre;
            check_compilation.active = td.is_compilation;
            spinbutton_tracknumber.set_value(td.tracknumber);
            spinbutton_disk.set_value(td.disk_number);
            spinbutton_year.set_value(td.year);
            
            File f = File.new_for_uri(td.item.uri);
            entry_uri.text         = f.get_path() != null ? f.get_path() : td.item.uri;
            return false;
        });
        return false;
    }
    
    private Label infolabel;
    private void setup_widgets() {
        try {
            dialog = new Dialog();
            
            dialog.set_modal(true);
            dialog.set_transient_for(main_window);
            
            builder.add_from_file(Config.XN_UIDIR + "metadat_title.ui");
            
            var mainvbox           = builder.get_object("vbox1")             as Gtk.Box;
            var okbutton           = builder.get_object("okbutton")          as Gtk.Button;
            var cancelbutton       = builder.get_object("cancelbutton")      as Gtk.Button;
            entry_artist           = builder.get_object("entry_artist")      as Gtk.Entry;
            entry_albumartist      = builder.get_object("entry_albumartist") as Gtk.Entry;
            entry_album            = builder.get_object("entry_album")       as Gtk.Entry;
            entry_title            = builder.get_object("entry_title")       as Gtk.Entry;
            check_compilation      = builder.get_object("check_compilation") as Gtk.CheckButton;
            spinbutton_tracknumber = builder.get_object("spinbutton_tracknumber") as Gtk.SpinButton;
            spinbutton_year        = builder.get_object("spinbutton_year")        as Gtk.SpinButton;
            spinbutton_disk        = builder.get_object("spinbutton_disk")        as Gtk.SpinButton;
            entry_genre            = builder.get_object("entry_genre")       as Gtk.Entry;
            entry_uri              = builder.get_object("entry_uri")         as Gtk.Entry;
            infolabel              = builder.get_object("label5")            as Gtk.Label;
            infolabel.label = _("With this dialog you can change the metatags in the according files. \nHandle with care!");;

            var artist_label       = builder.get_object("label1")            as Gtk.Label;
            artist_label.set_text(_("Title Artist") + ":");
            
            var aart_label         = builder.get_object("label_aa")          as Gtk.Label;
            aart_label.set_text(_("Album Artist") + ":");
            
            var album_label        = builder.get_object("label2")            as Gtk.Label;
            album_label.set_text(_("Album") + ":");
            
            var title_label        = builder.get_object("label3")            as Gtk.Label;
            title_label.set_text(_("Title") + ":");
            
            var genre_label        = builder.get_object("label_genre")       as Gtk.Label;
            genre_label.set_text(_("Genre") + ":");
            
            var uri_label          = builder.get_object("label_uri")         as Gtk.Label;
            uri_label.set_text(_("Uri") + ":");
            
            var year_label         = builder.get_object("label_year")        as Gtk.Label;
            year_label.set_text(_("Year") + ":");

            var trakno_label       = builder.get_object("tracknumberlabel")  as Gtk.Label;
            trakno_label.set_text(_("Track No.") + ":");

            var disk_label         = builder.get_object("disk_label")  as Gtk.Label;
            trakno_label.set_text(_("Disk No.") + ":");
            
            spinbutton_disk.set_numeric(true);
            spinbutton_disk.configure(new Gtk.Adjustment(0.0, 1.0, 999.0, 1.0, 1.0, 1.0), 1.0, (uint)0);
            spinbutton_disk.changed.connect( (sender) => {
                if((int)(((Gtk.SpinButton)sender).value) < 0.0 ) ((Gtk.SpinButton)sender).value = 0.0;
                if((int)(((Gtk.SpinButton)sender).value) > 999.0) ((Gtk.SpinButton)sender).value = 999.0;
            });
            spinbutton_tracknumber.set_numeric(true);
            spinbutton_tracknumber.configure(new Gtk.Adjustment(0.0, 0.0, 999.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
            spinbutton_tracknumber.changed.connect( (sender) => {
                if((int)(((Gtk.SpinButton)sender).value) < 0.0 ) ((Gtk.SpinButton)sender).value = 0.0;
                if((int)(((Gtk.SpinButton)sender).value) > 999.0) ((Gtk.SpinButton)sender).value = 999.0;
            });
            spinbutton_year.set_numeric(true);
            spinbutton_year.configure(new Gtk.Adjustment(0.0, 0.0, 2100.0, 1.0, 1.0, 0.0), 1.0, (uint)0);
            spinbutton_year.changed.connect( (sender) => {
                if((int)(((Gtk.SpinButton)sender).value) < 0.0 ) ((Gtk.SpinButton)sender).value = 0.0;
                if((int)(((Gtk.SpinButton)sender).value) > 2100.0) ((Gtk.SpinButton)sender).value = 2100.0;
            });
            ((Gtk.Box)this.dialog.get_content_area()).add(mainvbox);
            okbutton.clicked.connect(on_ok_button_clicked);
            cancelbutton.clicked.connect(on_cancel_button_clicked);
            
            this.dialog.set_title(_("xnoise - Edit metadata"));
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

        if(td_old == null)
            return;
        
        infolabel.label = EMPTYSTRING;
        TrackData td_new = copy_trackdata(td_old);
        if(entry_artist.text != null)
            td_new.artist = entry_artist.text.strip();
        if(entry_albumartist.text != null)
            td_new.albumartist = entry_albumartist.text.strip();
        if(entry_album.text != null)
            td_new.album  = entry_album.text.strip();
        if(entry_title.text != null)
            td_new.title  = entry_title.text.strip();
        if(entry_genre.text != null)
            td_new.genre  = entry_genre.text.strip();
        td_new.is_compilation = check_compilation.active;
        td_new.year         = spinbutton_year.get_value_as_int();
        td_new.tracknumber  = (uint)spinbutton_tracknumber.get_value_as_int();
        td_new.disk_number  = spinbutton_disk.get_value_as_int();
        
        do_track_rename(td_old, td_new);
        HashTable<TrackListModel.Column,string?> ntags = new HashTable<TrackListModel.Column,string?>(direct_hash, direct_equal);
        ntags.insert(TrackListModel.Column.ITEM, this.item.uri); // cheating - the uri is not an item
        ntags.insert(TrackListModel.Column.ARTIST, td_new.artist);
        ntags.insert(TrackListModel.Column.ALBUM, td_new.album);
        ntags.insert(TrackListModel.Column.TITLE, td_new.title);
        ntags.insert(TrackListModel.Column.GENRE, td_new.genre);
        if(td_new.year > 0)
            ntags.insert(TrackListModel.Column.YEAR, "%u".printf(td_new.year));
        if(td_new.tracknumber > 0)
            ntags.insert(TrackListModel.Column.TRACKNUMBER, "%u".printf(td_new.tracknumber));
        tlm.update_tracklist_data(ntags);
        
        Idle.add( () => {
            this.dialog.destroy();
            return false;
        });
    }
    
    private void do_track_rename(TrackData td_old, TrackData td_new) {
        var job = new Worker.Job(Worker.ExecutionType.ONCE, this.update_tag_job);
        TrackData[] tda = new TrackData[2];
        tda[0] = td_old;
        tda[1] = td_new;
        job.track_dat = tda;
        global.in_tag_rename = true;
        io_worker.push_job(job);
    }
    
    // job to update tag in files
    private bool update_tag_job(Worker.Job tag_job) {
        if(tag_job.track_dat[0].item.type == ItemType.LOCAL_AUDIO_TRACK ||
           tag_job.track_dat[0].item.type == ItemType.LOCAL_VIDEO_TRACK) {
            File f = File.new_for_uri(tag_job.track_dat[1].item.uri);
            if(!f.query_exists(null))
                return false;
            var tw = new TagWriter();
            bool ret = false;
            string[] paths = {};
            
            ret = tw.write_tag(f, tag_job.track_dat[1]);
            
            if(ret) {
                paths += f.get_path();
            }
            // TODO handle is_compilation for containing album
            media_importer.reimport_media_files(paths);
            
            var fin_job = new Worker.Job(Worker.ExecutionType.ONCE, this.finish_job);
            io_worker.push_job(fin_job);
        }
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

