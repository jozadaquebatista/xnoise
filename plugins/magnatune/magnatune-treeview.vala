/* magnatune-treeview.vala
 *
 * Copyright (C) 2013  Jörn Magens
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


using Gtk;
using Gdk;

using Xnoise;
using Xnoise.Resources;
using Xnoise.SimpleMarkup;


private class MagnatuneTreeView : Gtk.TreeView, ExternQueryable {
    public MagnatuneTreeStore mag_model = null;
    private unowned DockableMedia dock;
    private unowned MagnatuneWidget widg;
    //parent container of this widget (most likely scrolled window)
    private unowned Widget ow;
    private bool dragging;
    private Gtk.Menu menu;
    private unowned MagnatunePlugin plugin;
    private FlowingTextRenderer renderer;
    
    private const TargetEntry[] src_target_entries = {
        {"application/custom_dnd_data", TargetFlags.SAME_APP, 0}
    };
    
    private int _fontsize = 0;
    internal int fontsize {
        get {
            return _fontsize;
        }
        set {
            if (_fontsize == 0) { //intialization
                if((value < 7)||(value > 14)) _fontsize = 7;
                else _fontsize = value;
                Idle.add( () => {
                    font_description.set_size((int)(_fontsize * Pango.SCALE));
                    renderer.size_points = fontsize;
                    return false;
                });
            }
            else {
                if((value < 7)||(value > 14)) _fontsize = 7;
                else _fontsize = value;
                Idle.add( () => {
                    font_description.set_size((int)(_fontsize * Pango.SCALE));
                    renderer.size_points = fontsize;
                    return false;
                });
                Idle.add(update_view);
            }
        }
    }

    public MagnatuneTreeView(DockableMedia dock, 
                             MagnatuneWidget widg, 
                             Widget ow, 
                             MagnatunePlugin plugin) {
        this.plugin = plugin;
        this.dock = dock;
        this.widg = widg;
        this.ow = ow;
        this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
        mag_model = create_model();
        if(mag_model == null)
            return;
        setup_view();
        Idle.add(this.populate_model);
        this.get_selection().set_mode(SelectionMode.MULTIPLE);
        if(MagnatunePlugin.cancel.is_cancelled())
            return;
        Gtk.drag_source_set(this,
                            Gdk.ModifierType.BUTTON1_MASK,
                            src_target_entries,
                            Gdk.DragAction.COPY
                            );
        
        this.dragging = false;
        
        //Signals
        this.row_activated.connect(this.on_row_activated);
        this.drag_begin.connect(this.on_drag_begin);
        this.drag_data_get.connect(this.on_drag_data_get);
        this.drag_end.connect(this.on_drag_end);
        this.button_release_event.connect(this.on_button_release);
        this.button_press_event.connect(this.on_button_press);
        this.key_release_event.connect(this.on_key_released);
        
        this.plugin.login_state_change.connect( () => {
            print("login_state_change\n");
            mag_model.dbreader.username = this.plugin.username;
            mag_model.dbreader.password = this.plugin.password;
        });
        var context = this.get_style_context();
        context.save();
        context.add_class(STYLE_CLASS_PANE_SEPARATOR);
        Gdk.RGBA color = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
        this.override_background_color(StateFlags.NORMAL, color);
        context.restore();
    }
    
    ~MagnatuneTreeView() {        
        global.notify["active-dockable-media-name"].disconnect(on_active_dockable_media_changed);
    }
    
    private bool on_key_released(Gtk.Widget sender, Gdk.EventKey e) {
//        print("%d\n",(int)e.keyval);
        Gtk.TreeModel m;
        switch(e.keyval) {
            case Gdk.Key.Right: {
                Gtk.TreeSelection selection = this.get_selection();
                if(selection.count_selected_rows()<1) break;
                GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
                TreePath? treepath = selected_rows.nth_data(0);
                if(treepath.get_depth()>2) break;
                if(treepath!=null) this.expand_row(treepath, false);
                return true;
            }
            case Gdk.Key.Left: {
                Gtk.TreeSelection selection = this.get_selection();
                if(selection.count_selected_rows()<1) break;
                GLib.List<TreePath> selected_rows = selection.get_selected_rows(out m);
                TreePath? treepath = selected_rows.nth_data(0);
                if(treepath.get_depth()>2) break;
                if(treepath!=null) this.collapse_row(treepath);
                return true;
            }
            case Gdk.Key.Menu: {
                rightclick_menu_popup(e.time);
                return true;
            }
            default:
                break;
        }
        return false;
    }

    private bool on_button_press(Gdk.EventButton e) {
        Gtk.TreePath treepath = null;
        Gtk.TreeViewColumn column;
        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        int cell_x, cell_y;
        
        if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y))
            return true;
        
        switch(e.button) {
            case 1: {
                if(selection.count_selected_rows()<= 1) {
                    return false;
                }
                else {
                    if(selection.path_is_selected(treepath)) {
                        if(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
                           ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK)) {
                            selection.unselect_path(treepath);
                        }
                        return true;
                    }
                    else if(!(((e.state & Gdk.ModifierType.SHIFT_MASK)==Gdk.ModifierType.SHIFT_MASK)|
                            ((e.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK))) {
                        return true;
                    }
                    return false;
                }
            }
            case 3: {
                TreeIter iter;
                this.mag_model.get_iter(out iter, treepath);
                if(!selection.path_is_selected(treepath)) {
                    selection.unselect_all();
                    selection.select_path(treepath);
                }
                rightclick_menu_popup(e.time);
                return true;
            }
            default: {
                break;
            }
        }
        if(!(selection.count_selected_rows()>0 ))
            selection.select_path(treepath);
        return false;
    }

    private void rightclick_menu_popup(uint activateTime) {
        menu = create_rightclick_menu();
        if(menu != null)
            menu.popup(null, null, null, 0, activateTime);
    }

    public int get_model_item_column() {
        return (int)MagnatuneTreeStore.Column.ITEM;
    }
    
    public DataSource? get_data_source() {
        return (DataSource)mag_model.dbreader;
    }
    
    private Gtk.Menu create_rightclick_menu() {
        TreeIter iter;
        var rightmenu = new Gtk.Menu();
        GLib.List<TreePath> list;
        list = this.get_selection().get_selected_rows(null);
        ItemSelectionType itemselection = ItemSelectionType.SINGLE;
        if(list.length() > 1)
            itemselection = ItemSelectionType.MULTIPLE;
        Item? item = null;
        Array<unowned Xnoise.Action?> array = null;
        TreePath path = (TreePath)list.data;
        this.model.get_iter(out iter, path);
        this.model.get(iter, MagnatuneTreeStore.Column.ITEM, out item);
        array = itemhandler_manager.get_actions(item.type, ActionContext.QUERYABLE_EXTERNAL_MENU_QUERY, itemselection);
        for(int i =0; i < array.length; i++) {
            unowned Xnoise.Action x = array.index(i);
            //print("%s\n", x.name);
            var menu_item = new ImageMenuItem.from_stock((x.stock_item != null ? x.stock_item : Gtk.Stock.INFO), null);
            menu_item.set_label(x.info);
            menu_item.activate.connect( () => {
                x.action(item, this, null);
            });
            rightmenu.append(menu_item);
        }
        var sptr_item = new SeparatorMenuItem();
        rightmenu.append(sptr_item);
        var collapse_item = new ImageMenuItem.from_stock(Gtk.Stock.UNINDENT, null);
        collapse_item.set_label(_("Collapse all"));
        collapse_item.activate.connect( () => {
            this.collapse_all();
        });
        rightmenu.append(collapse_item);
        if(this.plugin != null && this.plugin.username != "" && this.plugin.username != null
           && this.plugin.password != "" && this.plugin.password != null && item.type != ItemType.COLLECTION_CONTAINER_ARTIST) {
            rightmenu.append(new SeparatorMenuItem());
            var downloaditem = new ImageMenuItem.from_stock(Gtk.Stock.SAVE, null);
            downloaditem.set_label(_("Download whole album to disk"));
            downloaditem.activate.connect( () => {
                var job = new Worker.Job(Worker.ExecutionType.ONCE, download_album_xml_job);
                job.item = item;
                io_worker.push_job(job);
            });
            rightmenu.append(downloaditem);
        }
        
        rightmenu.show_all();
        return rightmenu;
    }
    
    private bool download_album_xml_job(Worker.Job job) {
        string? sku = null;
        string artist = EMPTYSTRING, album = EMPTYSTRING;
        switch(job.item.type) {
            case ItemType.COLLECTION_CONTAINER_ARTIST:
                break;
            case ItemType.COLLECTION_CONTAINER_ALBUM:
                sku = this.mag_model.dbreader.get_sku_for_album(job.item.db_id);
                TrackData[]? tda = null;

                HashTable<ItemType,Item?>? item_ht =
                    new HashTable<ItemType,Item?>(direct_hash, direct_equal);
                item_ht.insert(job.item.type, job.item);
                tda = this.mag_model.dbreader.get_trackdata_for_album(EMPTYSTRING,
                                                                      CollectionSortMode.ARTIST_ALBUM_TITLE,
                                                                      item_ht);
//                tda = this.mag_model.dbreader.get_trackdata_by_albumid(EMPTYSTRING, job.item.db_id, job.item.stamp);
                if(tda != null && tda.length > 0) {
                    artist = tda[0].artist;
                    album  = tda[0].album;
                }
                break;
            case ItemType.STREAM:
                sku = this.mag_model.dbreader.get_sku_for_title(job.item.db_id);
                TrackData[] td = null;
                td = this.mag_model.dbreader.get_trackdata_for_item(global.searchtext, job.item);
                
                artist = td[0].artist;
                album  = td[0].album;
                break;
            default: break;
        }
        string download_url = this.mag_model.get_download_url(sku);
        //print("xml download_url: %s\n", download_url);
        Idle.add(() => {
            uint msg_id = userinfo.popup(UserInfo.RemovalType.CLOSE_BUTTON,
                                         UserInfo.ContentClass.WAIT,
                                         _("Downloading album ") + 
                                         "\"%s - %s\". ".printf(artist, album) +
                                         _("This may take some time..."),
                                         true,
                                         120,
                                         null);
            var job2 = new Worker.Job(Worker.ExecutionType.ONCE, download_xml_job);
            job2.set_arg("download_url", download_url);
            job2.set_arg("msg_id", msg_id);
            job2.set_arg("artist", artist);
            job2.set_arg("album",  album );
            io_worker.push_job(job2);
            return false;
        });
        return false;
    }
    
    private bool download_xml_job(Worker.Job job) {
        string download_url = (string)job.get_arg("download_url");
        var f = File.new_for_uri(download_url);
        var d = File.new_for_path("/tmp/magnatune" + Random.next_int().to_string() + ".xml");
        bool res = false;
        try {
            res = f.copy(d, FileCopyFlags.OVERWRITE,null, null);
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        if(res) {
            string s = "";
            uint8[] uaa = {};
            try {
                d.load_contents(null, out uaa, null);
                s = (string)uaa;
            }
            catch(Error e) {
                print("load contents%s\n", e.message);
            }
            var reader = new Xnoise.SimpleMarkup.Reader.from_string(s.replace("<br>", "").replace("</br>", "").replace("& ", "&amp; "));
            reader.read();
            var root = reader.root;
            if(root != null && root.has_children()) {
                var RESULT = root[0];
                if(RESULT != null && RESULT.has_children() && "result"== RESULT.name.down()) {
                    var mp3node = RESULT.get_child_by_name("URL_128KMP3ZIP");
                    //Playlist title
                    if(mp3node != null && mp3node.text != "") {
                        var mp3s = File.new_for_uri(process_download_url(mp3node.text));
                        var mp3d = File.new_for_path("/tmp/ARCH_"+
                                                     Random.next_int().to_string() +
                                                     "_mp3.zip");
                        try {
                            bool cres = mp3s.copy(mp3d, FileCopyFlags.OVERWRITE,null, null);
                            if(cres) {
                                var job2 = new Worker.Job(Worker.ExecutionType.ONCE, decompress_album_job);
                                job2.set_arg("source_url", mp3d.get_path());
                                job2.set_arg("artist", job.get_arg("artist"));
                                job2.set_arg("album",  job.get_arg("album"));
                                job2.set_arg("msg_id",  job.get_arg("msg_id"));
                                io_worker.push_job(job2);
                                try {d.delete(); }
                                catch(Error e) { print("%s\n", e.message); }
                                return false;
                            }
                        }
                        catch(Error e) {
                            print("%s\n", e.message);
                        }
                    }
                }
            }
            else {
                print("problem with memory map\n%s\n", s);
            }
        }
        print("finished!\n");
        try {
            d.delete();
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        return false;
    }

    private bool decompress_album_job(Worker.Job job) {
        var source = File.new_for_path((string)job.get_arg("source_url"));
        if(!source.query_exists())
            return false;
        string unzip;
        int exit_status;
        if((unzip = Environment.find_program_in_path("unzip")) != null) {
            //print("unzip found: %s\n", unzip);
            if(Environment.get_user_special_dir(UserDirectory.MUSIC) == null ||
               Environment.get_user_special_dir(UserDirectory.MUSIC) == "") {
                print("User special dir MUSIC is not available!\nAborting...\n");
                try {
                    source.delete();
                }
                catch(Error e) {
                    print("%s\n", e.message);
                    return false;
                }
            }
            try {
                Process.spawn_sync (Environment.get_user_special_dir(UserDirectory.MUSIC),
                                    { unzip, "-n", source.get_path() },
                                    null, 
                                    SpawnFlags.STDOUT_TO_DEV_NULL, 
                                    null, 
                                    null, 
                                    null, 
                                    out exit_status);
                Idle.add(() => {
                    userinfo.update_symbol_widget_by_id((uint)job.get_arg("msg_id"),
                                                        UserInfo.ContentClass.INFO);
                    string txt = _("Download finished for \"") + "%s - %s".printf(
                                      (string)job.get_arg("artist"),
                                      (string)job.get_arg("album")) + "\"";
                    userinfo.update_text_by_id((uint)job.get_arg("msg_id"), txt, true);
                    Timeout.add_seconds(5, () => {
                        userinfo.popdown((uint)job.get_arg("msg_id"));
                        return false;
                    });
                    string folder_path = GLib.Path.build_filename(
                                            Environment.get_user_special_dir(UserDirectory.MUSIC),
                                            (string)job.get_arg("artist"),
                                            (string)job.get_arg("album"));
                    media_importer.import_media_folder(folder_path);
                    return false;
                });
            }
            catch(GLib.Error e) {
                print("Failed unzipping magnatune album: %s\n", e.message);
            }
        }
        else {
            print("unzip not found in path!\n");
        }
        //print("DONE DECOMPRESSING\n");
        try {
            source.delete();
        }
        catch(Error e) {
            print("%s\n", e.message);
        }
        return false;
    }

    private string process_download_url(string url) {
        return url.replace("http://download.magnatune.com", "http://%s:%s@download.magnatune.com".printf(
           Uri.escape_string(mag_model.dbreader.username, null, true),
           Uri.escape_string(mag_model.dbreader.password, null, true)
        ));
    }
    
    private bool on_button_release(Gtk.Widget sender, Gdk.EventButton e) {
        Gtk.TreePath treepath;
        Gtk.TreeViewColumn column;
        int cell_x, cell_y;

        if((e.button != 1)|(this.dragging)) {
            this.dragging = false;
            return true;
        }
        if(((e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
            ((e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
            return true;
        }

        Gtk.TreeSelection selection = this.get_selection();
        int x = (int)e.x;
        int y = (int)e.y;
        if(!this.get_path_at_pos(x, y, out treepath, out column, out cell_x, out cell_y)) return false;
        selection.unselect_all();
        selection.select_path(treepath);

        return false;
    }

    private void on_drag_begin(Gtk.Widget sender, DragContext context) {
        this.dragging = true;
        List<unowned TreePath> treepaths;
        Gdk.drag_abort(context, Gtk.get_current_event_time());
        Gtk.TreeSelection selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        if(treepaths != null) {
            TreeIter iter;
            Pixbuf p;
            this.mag_model.get_iter(out iter, treepaths.nth_data(0));
            this.mag_model.get(iter, MusicBrowserModel.Column.ICON, out p);
            Gtk.drag_source_set_icon_pixbuf(this, p);
        }
        else {
            if(selection.count_selected_rows() > 1) {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
            }
            else {
                Gtk.drag_source_set_icon_stock(this, Gtk.Stock.DND);
            }
        }
    }

    private void on_drag_data_get(Gtk.Widget sender, 
                                  Gdk.DragContext context, 
                                  Gtk.SelectionData selection_data, 
                                  uint info, 
                                  uint etime) {
        List<unowned TreePath> treepaths;
        unowned Gtk.TreeSelection selection;
        selection = this.get_selection();
        treepaths = selection.get_selected_rows(null);
        DndData[] dat = {};
        if(treepaths.length() < 1)
            return;
        foreach(TreePath treepath in treepaths) { 
            DndData[] ddat = mag_model.get_dnd_data_for_path(ref treepath); 
            foreach(DndData u in ddat) {
                dat += u;
            }
        }
        Gdk.Atom dnd_atom = Gdk.Atom.intern(src_target_entries[0].target, true);
        unowned uchar[] data = (uchar[])dat;
        data.length = (int)(dat.length * sizeof(DndData));
        selection_data.set(dnd_atom, 8, data);
    }

    private void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
        this.dragging = false;
    }

    private void on_row_activated(Gtk.Widget sender, TreePath treepath, TreeViewColumn column) {
        if(treepath.get_depth() > 1) {
            Item? item = Item(ItemType.UNKNOWN);
            TreeIter iter;
            this.mag_model.get_iter(out iter, treepath);
            this.mag_model.get(iter, MagnatuneTreeStore.Column.ITEM, out item);
            ItemHandler? tmp = itemhandler_manager.get_handler_by_type(ItemHandlerType.TRACKLIST_ADDER);
            if(tmp == null)
                return;
            unowned Xnoise.Action? action = tmp.get_action(item.type, ActionContext.QUERYABLE_EXTERNAL_ITEM_ACTIVATED, ItemSelectionType.SINGLE);
            
            if(action != null)
                action.action(item, null, null);
            else
                print("action was null\n");
        }
        else {
            this.expand_row(treepath, false);
        }
    }

    private MagnatuneTreeStore? create_model() {
        return new MagnatuneTreeStore(this.dock, this, MagnatunePlugin.cancel);
    }

    private bool in_update_view = false;
    /* updates the view, leaves the original model untouched.
       expanded rows are kept as well as the scrollbar position */
    public bool update_view() {
        double scroll_position = this.widg.sw.vadjustment.value;
        in_update_view = true;
        this.set_model(null);
        this.set_model(mag_model);
        Idle.add( () => {
            in_update_view = false;
            return false;
        });
        this.widg.sw.vadjustment.set_value(scroll_position);
        this.widg.sw.vadjustment.value_changed();
        return false;
    }

    private class FlowingTextRenderer : CellRenderer {
        private const int PIXPAD   = 2; // space between pixbuf and text
        private const int WRAP_BUF = 2;
        
        private int maxiconwidth;
        private unowned Widget ow;
        private unowned Pango.FontDescription font_description;
        private unowned TreeViewColumn col;
        private int expander;
        private int hsepar;
        private int calculated_widh[3];
        private Pixbuf artist_unsel;
        private Pixbuf album_unsel;
        private Pixbuf title_unsel;
        private Pixbuf genre_unsel;
        
        public int level              { get; set; }
        public unowned Gdk.Pixbuf pix { get; set; }
        public string text            { get; set; }
        public int size_points        { get; set; }
        
        
        public FlowingTextRenderer(Widget ow, 
                                   Pango.FontDescription font_description,
                                   TreeViewColumn col,
                                   int expander,
                                   int hsepar) {
            GLib.Object();
            this.ow = ow;
            this.col = col;
            this.expander = expander;
            this.hsepar = hsepar;
            this.font_description = font_description;
            maxiconwidth = 0;
            calculated_widh[0] = 0;
            calculated_widh[1] = 0;
            calculated_widh[2] = 0;
        }
        
        
        public override void get_preferred_height_for_width(Gtk.Widget widget,
                                                            int width,
                                                            out int minimum_height,
                                                            out int natural_height) {
            Gdk.Window? w = ow.get_window();
            if(w == null) {
                print("no window\n");
                natural_height = minimum_height = 30;
                return;
            }
            int column_width = ow.get_allocated_width() - 2;
            int cw = col.get_width();
            int sum = 0;
            int iconwidth = 30;
            if(maxiconwidth < iconwidth)
                maxiconwidth = iconwidth;
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE)
                calculated_widh[level] = (level == 1 ? maxiconwidth : 17);
            else
                calculated_widh[level] = (level == 2 ? maxiconwidth : 17);
            sum = (level + 1) * (expander + 2 * hsepar) + (2 * (int)xpad) + calculated_widh[level] + 2 + PIXPAD; 
            //print("column_width: %d  sum: %d\n", column_width, sum);
            //print("column_width - sum :%d  level: %d\n", column_width - sum, level);
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( (int)((column_width - sum + WRAP_BUF) * Pango.SCALE));
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            int wi, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            natural_height = minimum_height = (pix != null ? 
                                                  int.max(he + 2, pix.get_height() + 2) : 
                                                  he + 2
                                              );
        }
    
        public override void get_size(Widget widget, Gdk.Rectangle? cell_area,
                                      out int x_offset, out int y_offset,
                                      out int width, out int height) {
            // function not used for gtk+-3.0 !
            x_offset = 0;
            y_offset = 0;
            width = 0;
            height = 0;
        }
        
        public override void render(Cairo.Context cr, Widget widget,
                                    Gdk.Rectangle background_area,
                                    Gdk.Rectangle cell_area,
                                    CellRendererState flags) {
            
            StyleContext context;
            var pango_layout = widget.create_pango_layout(text);
            pango_layout.set_font_description(this.font_description);
            pango_layout.set_alignment(Pango.Alignment.LEFT);
            pango_layout.set_width( 
                (int) ((cell_area.width - calculated_widh[level] - PIXPAD) * Pango.SCALE)
            );
            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
            //context = ow.get_style_context();
            //StateFlags state = ow.get_state_flags();
            //if((flags & CellRendererState.SELECTED) == 0) {
            //    Gdk.cairo_rectangle(cr, cell_area);
            //    Gdk.RGBA col = context.get_background_color(StateFlags.NORMAL);
            //    Gdk.cairo_set_source_rgba(cr, col);
            //    cr.fill();
            //}
            int wi = 0, he = 0;
            pango_layout.get_pixel_size(out wi, out he);
            
            
            Gdk.Pixbuf p = null;
            if((flags & CellRendererState.SELECTED) == 0) {
                switch(level) {
                    case 0:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            if(text == VARIOUS_ARTISTS) {
                                p = IconRepo.get_themed_pixbuf_icon("system-users-symbolic", 
                                                      16, widget.get_style_context());
                                break;
                            }
                            if(artist_unsel == null)
                                artist_unsel = 
                                    IconRepo.get_themed_pixbuf_icon("avatar-default-symbolic", 
                                                                16, widget.get_style_context());
                            p = artist_unsel;
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            if(genre_unsel == null)
//                                genre_unsel = 
//                                    IconRepo.get_themed_pixbuf_icon("emblem-documents-symbolic", 
//                                                                16, widget.get_style_context());
//                            p = genre_unsel;
//                        }
                        break;
                    case 1:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            if(pix != null) {
                                p = pix;
                                break;
                            }
                            if(album_unsel == null)
                                album_unsel = 
                                    IconRepo.get_themed_pixbuf_icon("media-optical-symbolic", 
                                                                16, widget.get_style_context());
                            p = album_unsel;
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            if(artist_unsel == null)
//                                artist_unsel = 
//                                    IconRepo.get_themed_pixbuf_icon("avatar-default-symbolic", 
//                                                                16, widget.get_style_context());
//                            p = artist_unsel;
//                        }
                        break;
                    case 2:
                    default:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            if(title_unsel == null)
                                title_unsel = 
                                    IconRepo.get_themed_pixbuf_icon("audio-x-generic-symbolic", 
                                                                16, widget.get_style_context());
                            p = title_unsel;
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            if(pix != null) {
//                                p = pix;
//                                break;
//                            }
//                            if(album_unsel == null)
//                                album_unsel = 
//                                    IconRepo.get_themed_pixbuf_icon("media-optical-symbolic", 
//                                                                16, widget.get_style_context());
//                            p = album_unsel;
//                        }
                        break;
                }
            }
            else {
                switch(level) {
                    case 0:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            if(text == VARIOUS_ARTISTS) {
                                p = IconRepo.get_themed_pixbuf_icon("system-users-symbolic", 
                                                      16, widget.get_style_context());
                                break;
                            }
                            p = IconRepo.get_themed_pixbuf_icon("avatar-default-symbolic", 
                                                            16, widget.get_style_context());
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            p = IconRepo.get_themed_pixbuf_icon("emblem-documents-symbolic", 
//                                                                16, widget.get_style_context());
//                        }
                        break;
                    case 1:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            if(pix != null) {
                                p = pix;
                                break;
                            }
                            p = IconRepo.get_themed_pixbuf_icon("media-optical-symbolic", 
                                                                16, widget.get_style_context());
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            p = IconRepo.get_themed_pixbuf_icon("avatar-default-symbolic", 
//                                                                16, widget.get_style_context());
//                        }
                        break;
                    case 2:
                    default:
//                        if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                            p = IconRepo.get_themed_pixbuf_icon("audio-x-generic-symbolic", 
                                                                16, widget.get_style_context());
//                        }
//                        else {//(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM)
//                            if(pix != null) {
//                                p = pix;
//                                break;
//                            }
//                            p = IconRepo.get_themed_pixbuf_icon("media-optical-symbolic", 
//                                                                16, widget.get_style_context());
//                        }
                        break;
                }
            }
            if(p != null) {
                int pixheight = p.get_height();
                int x_offset = p.get_width();
                if(calculated_widh[level] > x_offset)
                    x_offset = (int)((calculated_widh[level] - x_offset) / 2.0);
                else
                    x_offset = 0;
                if(cell_area.height > pixheight)
                    Gdk.cairo_set_source_pixbuf(cr, 
                                                p, 
                                                cell_area.x + x_offset, 
                                                cell_area.y + (cell_area.height -pixheight)/2
                    );
                else
                    Gdk.cairo_set_source_pixbuf(cr,
                                                p, 
                                                cell_area.x + x_offset, 
                                                cell_area.y
                    );
                
                cr.paint();
            }
            //print("calculated_widh[level]: %d  level: %d\n", calculated_widh[level], level);
            context = widget.get_style_context();
            if(cell_area.height > he)
                context.render_layout(cr, 
                                      calculated_widh[level] + 
                                          PIXPAD + cell_area.x,
                                      cell_area.y +  (cell_area.height -he)/2,
                                      pango_layout);
            else
                context.render_layout(cr, 
                                      calculated_widh[level] + 
                                          PIXPAD + cell_area.x, 
                                      cell_area.y, 
                                      pango_layout);
        }
    }//    private class FlowingTextRenderer : CellRendererText {
//        private int maxiconwidth;
//        private unowned Widget ow;
//        private unowned Pango.FontDescription font_description;
//        private unowned TreeViewColumn col;
//        private int expander;
//        private int hsepar;
//        private int calculated_widh[3];
//        
//        public int level    { get; set; }
//        public unowned Gdk.Pixbuf pix { get; set; }
//        
//        public FlowingTextRenderer(Widget ow, Pango.FontDescription font_description, TreeViewColumn col, int expander, int hsepar) {
//            GLib.Object();
//            this.ow = ow;
//            this.col = col;
//            this.expander = expander;
//            this.hsepar = hsepar;
//            this.font_description = font_description;
//            maxiconwidth = 0;
//            calculated_widh[0] = 0;
//            calculated_widh[1] = 0;
//            calculated_widh[2] = 0;
//        }
//        
//        public override void get_preferred_height_for_width(Gtk.Widget widget,
//                                                            int width,
//                                                            out int minimum_height,
//                                                            out int natural_height) {
//            Gdk.Window? w = ow.get_window();
//            if(w == null) {
//                //print("no window (magnatune)\n");
//                natural_height = minimum_height = 30;
//                return;
//            }
//            int column_width = ow.get_allocated_width() - 2; //col.get_width();
////            int column_width = col.get_width();
//            int sum = 0;
//            int iconwidth = 30;//(pix == null) ? 16 : pix.get_width();
////            int iconwidth = (pix == null) ? 16 : pix.get_width();
//            if(maxiconwidth < iconwidth)
//                maxiconwidth = iconwidth;
//            calculated_widh[level] = maxiconwidth;
//            sum = (level + 1) * (expander + 2 * hsepar) + (2 * (int)xpad) + maxiconwidth + 2; 
//            //print("column_width - sum :%d  level: %d\n", column_width - sum, level);
//            var pango_layout = widget.create_pango_layout(text);
//            pango_layout.set_font_description(this.font_description);
//            pango_layout.set_alignment(Pango.Alignment.LEFT);
//            pango_layout.set_width( (int)((column_width - sum) * Pango.SCALE));
//            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
//            int wi, he = 0;
//            pango_layout.get_pixel_size(out wi, out he);
//            natural_height = minimum_height = he;
//        }
//    
//        public override void get_size(Widget widget, Gdk.Rectangle? cell_area,
//                                      out int x_offset, out int y_offset,
//                                      out int width, out int height) {
//            // function not used for gtk+-3.0 !
//            x_offset = 0;
//            y_offset = 0;
//            width = 0;
//            height = 0;
//        }
//    
//        public override void render(Cairo.Context cr, Widget widget,
//                                    Gdk.Rectangle background_area,
//                                    Gdk.Rectangle cell_area,
//                                    CellRendererState flags) {
//            StyleContext context;
//            //print("cell_area.width: %d level: %d\n", cell_area.width, level);
//            var pango_layout = widget.create_pango_layout(text);
//            pango_layout.set_font_description(this.font_description);
//            pango_layout.set_alignment(Pango.Alignment.LEFT);
//            pango_layout.set_width( (int)((calculated_widh[level] > cell_area.width ? calculated_widh[level] : cell_area.width) * Pango.SCALE));
//            pango_layout.set_wrap(Pango.WrapMode.WORD_CHAR);
//            context = widget.get_style_context();
//            int wi = 0, he = 0;
//            pango_layout.get_pixel_size(out wi, out he);
//            if(cell_area.height > he)
//                context.render_layout(cr, cell_area.x, cell_area.y + (cell_area.height -he)/2, pango_layout);
//            else
//                context.render_layout(cr, cell_area.x, cell_area.y, pango_layout);
//        }
//    }

//    private CellRendererText renderer = null;
//    private Pango.FontDescription font_description;
//    private int last_width;
//    
//    private int _fontsize = 0;
//    internal int fontsize {
//        get {
//            return _fontsize;
//        }
//        set {
//            if (_fontsize == 0) { //intialization
//                if((value < 7)||(value > 14)) _fontsize = 7;
//                else _fontsize = value;
//                Idle.add( () => {
//                    font_description.set_size((int)(_fontsize * Pango.SCALE));
//                    renderer.size_points = fontsize;
//                    return false;
//                });
//            }
//            else {
//                if((value < 7)||(value > 14)) _fontsize = 7;
//                else _fontsize = value;
//                Idle.add( () => {
//                    font_description.set_size((int)(_fontsize * Pango.SCALE));
//                    renderer.size_points = fontsize;
//                    return false;
//                });
//                Idle.add(update_view);
//            }
//        }
//    }
    private Pango.FontDescription font_description;
    private int last_width;


    private void setup_view() {
        
        this.row_collapsed.connect(on_row_collapsed);
        this.row_expanded.connect(on_row_expanded);
        
        this.set_size_request(300, 500);
        
//        fontsize = Params.get_int_value("fontsizeMB");
        Gtk.StyleContext context = this.get_style_context();
        font_description = context.get_font(StateFlags.NORMAL).copy();
        font_description.set_size((int)(global.fontsize_dockable * Pango.SCALE));
        
        var column = new TreeViewColumn();
        
        int expander = 0;
        this.style_get("expander-size", out expander);
        int hsepar = 0;
        this.style_get("horizontal-separator", out hsepar);
        renderer = new FlowingTextRenderer(this.ow, font_description, column, expander, hsepar);
        
        global.notify["active-dockable-media-name"].connect(on_active_dockable_media_changed);
        
        this.ow.size_allocate.connect_after( (s, a) => {
            unowned TreeViewColumn tvc = this.get_column(0);
            int current_width = this.ow.get_allocated_width();
            if(last_width == current_width)
                return;
            
            last_width = current_width;
            
            tvc.max_width = tvc.min_width = current_width - 20;
            TreeModel? xm = this.get_model();
            if(xm != null && !in_update_view)
                xm.foreach( (mo, pt, it) => {
                    if(mo == null)
                        return true;
                    mo.row_changed(pt, it);
                    return false;
                });
        });
        
//        var pixbufRenderer = new CellRendererPixbuf();
//        pixbufRenderer.stock_id = Gtk.Stock.GO_FORWARD;
//        pixbufRenderer.set_fixed_size(30, -1);
        
        column.pack_start(renderer, false);
//        column.pack_start(pixbufRenderer, false);
//        column.add_attribute(pixbufRenderer, "pixbuf", MagnatuneTreeStore.Column.ICON);
        column.add_attribute(renderer, "text", MagnatuneTreeStore.Column.VIS_TEXT); // no markup!!
        column.add_attribute(renderer, "level", MagnatuneTreeStore.Column.LEVEL);
        column.add_attribute(renderer, "pix", MagnatuneTreeStore.Column.ICON);
        this.insert_column(column, -1);
        
        this.headers_visible = false;
        this.enable_search = false;
        
        global.notify["fontsize-dockable"].connect( () => {
            this.fontsize = global.fontsize_dockable;
        });
    }
    
    private void on_active_dockable_media_changed() {
        string n = global.active_dockable_media_name;
        if(n == name_buffer)
            return;
        if(n == this.dock.name())
            last_width++;
        name_buffer = n;
    }

    private string name_buffer;
    
    private void on_row_expanded(TreeIter iter, TreePath path) {
        mag_model.load_children(ref iter);
    }
    
    private void on_row_collapsed(TreeIter iter, TreePath path) {
        mag_model.unload_children(ref iter);
    }
    
    private bool populate_model() {
        if(MagnatunePlugin.cancel.is_cancelled())
            return false;
        mag_model.filter();
        return false;
    }
}

