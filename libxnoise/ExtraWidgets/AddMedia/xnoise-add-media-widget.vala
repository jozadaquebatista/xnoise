/* xnoise-add-media-widget.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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



private class Xnoise.AddMediaWidget : Gtk.Box {

    private enum Column {
        ICON,
        ITEMTYPE,
        LOCATION,
        COL_COUNT
    }
    
    private const string XNOISEICON = "xnoise";
    private ListStore listmodel;
    private TreeView tv;
    private Button bok;
    private bool fullrescan;
    private unowned Main xn;
    
    public Gtk.Builder builder;

    public AddMediaWidget() {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        xn = Main.instance;
        builder = new Gtk.Builder();
        setup_widgets();
        
        fill_media_list();
        
        this.show_all();
    }

    internal void update() {
        fill_media_list();
    }
    
    private void fill_media_list() {
        return_if_fail(listmodel != null);
        listmodel.clear();
        Worker.Job job;
        job = new Worker.Job(Worker.ExecutionType.ONCE, fill_media_list_job);
        db_worker.push_job(job);
    }
    
    private bool fill_media_list_job(Worker.Job job) {
        //add folders
        Item[] mfolders = db_reader.get_media_folders();
        
        //add streams to list
        Item[] tmp = db_reader.get_stream_items("");
        Item[] streams = {};
        
        for(int j = tmp.length -1; j >= 0; j--) // reverse
            streams += tmp[j];
        
        Gtk.Invisible w = new Gtk.Invisible();
        Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.MENU);
        
        Idle.add( () => {
            foreach(Item? i in mfolders) {
                File f = File.new_for_uri(i.uri);
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.ICON,      folder_icon,
                              Column.LOCATION,  f.get_path(),
                              Column.ITEMTYPE,  i.type
                );
            }
            foreach(Item? i in streams) {
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.ICON,      icon_repo.radios_icon_menu,
                              Column.LOCATION,  i.uri,
                              Column.ITEMTYPE,  i.type
                );
            }
            return false;
        });
        return false;
    }

    private Item[] harvest_media_locations() {
        Item[] media_items = {};
        listmodel.foreach( (sender, mypath, myiter) => {
            string d_uri;
            ItemType tp;
            sender.get(myiter,
                       Column.LOCATION, out d_uri,
                       Column.ITEMTYPE, out tp//,
            );
            switch(tp) {
                case ItemType.LOCAL_FOLDER:
                    File f = File.new_for_path(d_uri);
                    Item? item = Item(ItemType.LOCAL_FOLDER, f.get_uri(), -1);
                    media_items += item;
                    break;
                case ItemType.STREAM:
                case ItemType.PLAYLIST:
                    Item? item = Item(tp, d_uri, -1);
                    media_items += item;
                    break;
                default:
                    print("Error: unhandled media storage type: %s\n", ((int)tp).to_string());
                    break;
            }
            return false;
        });
        return media_items;
    }

    private void setup_widgets() {
        ScrolledWindow tvscrolledwindow = null;
        try {
            builder.add_from_file(Config.XN_UIDIR + "add_media.ui");
            
            var headline           = builder.get_object("addremove_headline") as Label;
            headline.set_alignment(0.0f, 0.5f);
            headline.use_markup= true;
            headline.set_markup("<span size=\"xx-large\"><b> %s </b></span>".printf(Markup.escape_text(_("Add or Remove media"))));

            var mainvbox           = builder.get_object("mainvbox") as Gtk.Box;
            tvscrolledwindow       = builder.get_object("tvscrolledwindow") as ScrolledWindow;
            var baddfolder         = builder.get_object("addfolderbutton") as ToolButton;
            var baddradio          = builder.get_object("streambutton") as ToolButton;
            var brem               = builder.get_object("removebutton") as ToolButton;
            var descriptionlabel   = builder.get_object("descriptionlabel") as Label;
            bok                    = builder.get_object("okbutton") as Button;
            bok.sensitive          = !global.media_import_in_progress;
            
            var fullrescan_switch  = builder.get_object("fullrescan_switch") as Gtk.Switch;
            fullrescan_switch.tooltip_markup = 
                Markup.printf_escaped(_("If selected, all media folders will be fully rescanned"));
            fullrescan_switch.notify["active"].connect( (s,p) => {
                //print("active toggled. New val = %s\n", ((Switch)s).active.to_string());
                this.fullrescan = ((Switch)s).active;
            });
            
            baddfolder.tooltip_markup = Markup.printf_escaped(_("Add local folder"));
            baddradio.tooltip_markup  = Markup.printf_escaped(_("Add media stream"));
            brem.tooltip_markup       = Markup.printf_escaped(_("Remove"));
            
            var fullrescan_label   = builder.get_object("fullrescan_label") as Label; 
            fullrescan_label.label = _("Do full rescan");
            descriptionlabel.label = _("Select local media folders or internet media streams. \nAll media sources will be available via xnoise's library.");
            this.pack_start(mainvbox, true, true, 0);
            
            bok.clicked.connect(on_ok_button_clicked);
            
            baddfolder.clicked.connect(on_add_folder_button_clicked);
            baddradio.clicked.connect(on_add_radio_button_clicked);
            brem.clicked.connect(on_remove_button_clicked);
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
        
        tv = new TreeView();
        tv.headers_visible = false;
        listmodel = new ListStore(Column.COL_COUNT, 
                                  typeof(Gdk.Pixbuf), 
                                  typeof(ItemType), 
                                  typeof(string));
        
        //NAME
        var column = new TreeViewColumn();
        var rendererpb = new CellRendererPixbuf();
        column.pack_start(rendererpb, false);
        column.add_attribute(rendererpb, "pixbuf", Column.ICON);
        tv.insert_column(column, -1);
        
        // LOCATION
        column = new TreeViewColumn();
        var renderer = new CellRendererText();
        column.pack_start(renderer, false);
        column.add_attribute(renderer, "text", Column.LOCATION);
        column.title = _("Location");
        tv.insert_column(column, -1);
        
        tvscrolledwindow.add(tv);
        
        tv.set_model(listmodel);
        tv.show();
        
        global.notify["media-import-in-progress"].connect( () => {
            if(!global.media_import_in_progress) {
                this.update();
                bok.sensitive = true;
            }
            else {
                bok.sensitive = false;
            }
        });
    }

    private void on_ok_button_clicked(Gtk.Button sender) {
        main_window.mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
//        main_window.dialognotebook.set_current_page(0);
        bool interrupted_populate_model = false;
        if(main_window.musicBr.mediabrowsermodel.populating_model) {
            interrupted_populate_model = true; 
            // that means we have to complete filling of the model after import
            //print("was still populating model\n");
        }
        var prg_bar = new Gtk.ProgressBar();
        prg_bar.set_fraction(0.0);
        prg_bar.set_text("0 / 0");
        
        Idle.add(() => {
            main_window.mainview_box.select_main_view(TRACKLIST_VIEW_NAME);
            return false;
        });
        
        Timeout.add(200, () => {
            uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
                                UserInfo.ContentClass.WAIT,
                                _("Importing media data. This may take some time..."),
                                true,
                                5,
                                prg_bar);
            Item[] media_items = harvest_media_locations();
            global.media_import_in_progress = true;
            media_importer.import_media_groups(media_items,
                                               msg_id,
                                               fullrescan,
                                               interrupted_populate_model);
            return false;
        });
    }

    private void on_add_folder_button_clicked() {
        Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
            _("Select media folder"),
            main_window,
            Gtk.FileChooserAction.SELECT_FOLDER,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.Stock.OPEN,
            Gtk.ResponseType.ACCEPT,
            null);
        fcdialog.set_current_folder(Environment.get_home_dir());
        if (fcdialog.run() == Gtk.ResponseType.ACCEPT) {
            File f = File.new_for_path(fcdialog.get_filename());
            Gtk.Invisible w = new Gtk.Invisible();
            Gdk.Pixbuf folder_icon = w.render_icon_pixbuf(Gtk.Stock.DIRECTORY, IconSize.MENU);
            TreeIter iter;
            listmodel.append(out iter);
            listmodel.set(iter,
                          Column.ICON,      folder_icon,
                          Column.LOCATION,  f.get_path(),
                          Column.ITEMTYPE,  ItemType.LOCAL_FOLDER
                          );
        }
        fcdialog.destroy();
        fcdialog = null;
    }


    private Gtk.Dialog radiodialog;
    private Gtk.Entry radioentry;

    private void on_add_radio_button_clicked() {
        radiodialog = new Gtk.Dialog();
        radiodialog.set_modal(true);
        radiodialog.set_transient_for(main_window);
        
        radioentry = new Gtk.Entry();
        radioentry.set_width_chars(50);
        radioentry.secondary_icon_stock = Gtk.Stock.CLEAR;
        radioentry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
        radioentry.icon_press.connect( (s, p0, p1) => { // s:Entry, p0:Position, p1:Gdk.Event
            if(p0 == Gtk.EntryIconPosition.SECONDARY) s.text = EMPTYSTRING;
        });
        ((Gtk.Box)radiodialog.get_content_area()).pack_start(radioentry, true, true, 0);
        
        var radiocancelbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.CANCEL, 0);
        radiocancelbutton.clicked.connect( () => {
            radiodialog.close();
            radiodialog = null;
        });
        
        var radiookbutton = (Gtk.Button)radiodialog.add_button(Gtk.Stock.OK, 1);
        radiookbutton.clicked.connect( () => {
            if((radioentry.text!=null)&&
               (radioentry.text.strip() != EMPTYSTRING)) {
                TreeIter iter;
                listmodel.append(out iter);
                listmodel.set(iter,
                              Column.ICON,      icon_repo.radios_icon_menu,
                              Column.LOCATION,  radioentry.text.strip(),
                              Column.ITEMTYPE,  ItemType.STREAM//,
                              );
            }
            radiodialog.close();
            radiodialog = null;
        });
        
        radiodialog.destroy_event.connect( () => {
            radiodialog = null;
            return true;
        });
        radiodialog.set_icon_name(XNOISEICON);
        radiodialog.set_title(_("Add internet radio link"));
        radiodialog.set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
        radiodialog.show_all();
    }

    // Removes entry from the media library
    private void on_remove_button_clicked() {
        Gtk.TreeSelection selection = tv.get_selection ();
        if(selection.count_selected_rows() > 0) {
            TreeIter iter;
            selection.get_selected(null, out iter);
            listmodel.remove(iter);
        }
    }
}

