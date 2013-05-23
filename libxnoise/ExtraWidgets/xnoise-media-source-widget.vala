/* xnoise-media-source-widget.vala
 *
 * Copyright (C) 2012 -2013  Jörn Magens
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


// Vala does not seem to allow nested interfaces
private interface Xnoise.MediaSelector : Gtk.Widget {
    public abstract string selected_dockable_media {get; set;} 
    public abstract void select_without_signal_emmission(string name);
    public abstract void expand_all();
}


public class Xnoise.MediaSoureWidget : Gtk.Box, Xnoise.IParams {
    private SideBarHeadline current_selected_media;
    private Gtk.Notebook notebook;
    private unowned Xnoise.MainWindow mwindow;
    
    public Gtk.Entry search_entry              { get; private set; }
    
    private MediaSelector media_source_selector = null;// { get; private set; }
    private ScrolledWindow media_source_selector_window = null;
    private Box media_source_selector_box = null;
    
    public MediaSoureWidget(Xnoise.MainWindow mwindow) {
        Object(orientation:Orientation.VERTICAL, spacing:0);
        Params.iparams_register(this);
        this.mwindow = mwindow;
        
        this.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
        setup_widgets();
        var context = this.get_style_context();
        context.save();
        context.add_class(STYLE_CLASS_PANE_SEPARATOR);
        Gdk.RGBA color = context.get_background_color(StateFlags.NORMAL); //TODO // where is the right color?
        this.override_background_color(StateFlags.NORMAL, color);
        context.restore();
    }
    
    public void set_focus_on_selector() {
        this.media_source_selector.grab_focus();
    }
    
    public void select_dockable_by_name(string name, bool emmit_signal = false) {
        //print("dockable %s selected\n", name);
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d == null) {
            print("dockable %s does not exist\n", name);
            return;
        }
        if(d.widget == null) {
            print("dockable's widget is null for %s\n", name);
            return;
        }
        assert(notebook != null && notebook is Gtk.Container);
        int i = notebook.page_num(d.widget);
        if(i > -1)
            notebook.set_current_page(i);
    }
    
    private void add_page(DockableMedia d) {
        Gtk.Widget? widg = d.create_widget(mwindow);
        if(widg == null)
            return;
        
        widg.show_all();
        notebook.show_all();
        assert(notebook != null && notebook is Gtk.Container);
        widg.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
        notebook.append_page(widg, new Label("x"));
    }
    
    private void remove_page(string name) {
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d != null) {
            d.remove_main_view();
            assert(notebook != null && notebook is Gtk.Container);
            notebook.remove_page(notebook.page_num(d.widget));
        }
        
        Idle.add( () => {
            set_focus_on_selector();
            return false;
        });
    }
    
    private void on_media_inserted(string name) {
        DockableMedia? d = dockable_media_sources.lookup(name);
        if(d == null)
            return;
        add_page(d);
    }
    
    private void setup_widgets() {
        var buff = new Gtk.EntryBuffer(null);
        this.search_entry = new Gtk.Entry.with_buffer(buff); // media_source_widget.search_entry;
        //this.search_entry.get_style_context().add_class(STYLE_CLASS_CELL);
        this.search_entry.events = this.search_entry.events |
                                   Gdk.EventMask.ENTER_NOTIFY_MASK |
                                   Gdk.EventMask.LEAVE_NOTIFY_MASK;
        this.search_entry.secondary_icon_stock = Gtk.Stock.CLEAR;
        this.search_entry.set_icon_activatable(Gtk.EntryIconPosition.PRIMARY, false);
        this.search_entry.set_icon_activatable(Gtk.EntryIconPosition.SECONDARY, true);
        this.search_entry.set_sensitive(true);
        this.search_entry.set_placeholder_text (_("Search..."));
        
//        search_entry.margin_top = 2;
//        search_entry.margin_bottom = 1;
        this.pack_start(search_entry, false, false, 0);
            
        // DOCKABLE MEDIA
        
        notebook = new Gtk.Notebook();
        notebook.set_show_tabs(false);
        notebook.show_border = true;
        notebook.get_style_context().add_class(STYLE_CLASS_SIDEBAR);
        
        this.media_source_selector_box = new Box(Orientation.VERTICAL, 0);
        
        var coll_headline = new SideBarHeadline(_("Media Collections"));
        coll_headline.can_focus = false;
        this.pack_start(coll_headline, false, false, 0);
        this.pack_start(media_source_selector_box, false, false, 0);
        
        // initialize the proper type of media source selector
        read_params_data();
        build_media_selector();
        
        global.notify["active-dockable-media-name"].connect(() => {
            select_dockable_by_name(global.active_dockable_media_name, false);
        });
        
//        notebook.margin_top = 2;
        current_selected_media = new SideBarHeadline("");//_("Media Source"));
        current_selected_media.can_focus = false;
        this.pack_start(current_selected_media, false, false, 0);
        this.pack_start(notebook, true, true, 0);
        
        //load pre-existing
        foreach(string n in dockable_media_sources.get_keys()) {
            DockableMedia? d = null;
            d = dockable_media_sources.lookup(n);
            if(d == null)
                continue;
            add_page(d);
        }
        media_source_selector.expand_all();
        
        dockable_media_sources.media_removed.connect(on_media_removed);
        dockable_media_sources.media_inserted.connect(on_media_inserted);
        
        DockableMedia? dm_mb = null;
        assert((dm_mb = dockable_media_sources.lookup("MusicBrowserDockable")) != null);
        string dname = dm_mb.name();
        media_source_selector.selected_dockable_media = dname;
        current_selected_media.set_headline("");//dm_mb.headline());
//        global.notify["active-dockable-media-name"].connect( () => {
//            DockableMedia? dx = dockable_media_sources.lookup(global.active_dockable_media_name);
//            if(dx != null)
//                current_selected_media.set_headline(dx.headline());
//        });
//        this.margin_left = 1;
    }
    
    private string _media_source_selector_type = "tree";
    public string media_source_selector_type {
        get {
            return _media_source_selector_type;
        }
        set {
            if(value == _media_source_selector_type)
                return;
            _media_source_selector_type = value;
            build_media_selector();
        }
    }
    
    private void build_media_selector() {
        // clear the box and remove all references
        if(media_source_selector_box != null) {
            foreach(Widget w in media_source_selector_box.get_children()) {
                media_source_selector_box.remove(w);
            }
            media_source_selector = null;
            media_source_selector_window = null;
        }
        switch(media_source_selector_type) {
            case "combobox":
                media_source_selector = new ComboMediaSelector();
                media_source_selector_box.add(media_source_selector);
                break;
            default:
                media_source_selector = new TreeMediaSelector(this);
                var mss_sw = new ScrolledWindow(null, null);
                mss_sw.set_policy(PolicyType.NEVER, PolicyType.NEVER);
//                mss_sw.set_border_width(1);
                mss_sw.add(media_source_selector);
                mss_sw.set_shadow_type(ShadowType.NONE);
                media_source_selector_box.add(mss_sw);
//                mss_sw.get_style_context().add_class(STYLE_CLASS_BACKGROUND);
//                var sep = new SeparationArea();
//                sep.show();
//                media_source_selector_box.pack_start(sep, false, false, 0);
                media_source_selector_window = mss_sw;
                break;
        }
        media_source_selector.selected_dockable_media = global.active_dockable_media_name;
        media_source_selector.expand_all();
        this.show_all();
    }
    
    private void on_media_removed(string name) {
        remove_page(name);
    }
    
    public void read_params_data() {
        _media_source_selector_type = Params.get_string_value("media_source_selector_type");
    }

    public void write_params_data() {
        Params.set_string_value("media_source_selector_type", media_source_selector_type);
    }
}


//private class Xnoise.SeparationArea : Gtk.DrawingArea {
//    private int HEIGHT = 1;
//    
//    public SeparationArea() {
//        this.get_style_context().add_class(STYLE_CLASS_SEPARATOR);
//    }
//    
//    public override bool draw(Cairo.Context cr) {
//        Allocation allocation;
//        this.get_allocation(out allocation);
//        var context = this.get_style_context();
//        render_line(context, cr, 4, 0, 
//                                 get_allocated_width(), 0);
//        return false;
//    }
//    
//    public override void get_preferred_height(out int minimum_height, out int natural_height) {
//        minimum_height = natural_height = HEIGHT;
//    }
//}

