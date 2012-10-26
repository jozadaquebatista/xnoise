/* xnoise-videoscreen.vala
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
using Cairo;

using Xnoise;
using Xnoise.Resources;
using Xnoise.Utilities;


private class Xnoise.VideoViewWidget : Gtk.Box, IMainView {
    private const string UI_FILE = Config.XN_UIDIR + "video.ui";
    
    private unowned MainWindow win;
    internal Gtk.Box videovbox;
    internal unowned VideoScreen videoscreen;
    internal SerialButton sbutton;
    
    public VideoViewWidget(MainWindow win) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.win = win;
        setup_widgets();
    }
    
    public string get_view_name() {
        return VIDEOVIEW_NAME;
    }
    
    private void setup_widgets() {
        Gtk.Box inner_box = new Box(Orientation.VERTICAL, 0);
        Gtk.Box bottom_box = new Box(Orientation.HORIZONTAL, 0);
        this.videovbox = new Box(Orientation.VERTICAL, 0);
        this.videoscreen = gst_player.videoscreen;
        videovbox.pack_start(videoscreen, true ,true ,0);
        inner_box.pack_start(videovbox, true ,true ,0);
        this.pack_start(inner_box, true, true, 0);
        var hide_button_1 = new Gtk.Button();
        hide_button_1.can_focus = false;
        hide_button_1.clicked.connect(win.toggle_media_browser_visibility);
        var hide_button_image = new Gtk.Image.from_stock(Stock.GOTO_FIRST, IconSize.MENU);
        hide_button_1.add(hide_button_image);
        hide_button_1.set_relief(ReliefStyle.NONE);
        
        bottom_box.pack_start(hide_button_1, false, false, 0);
        bottom_box.pack_start(new Label(""), true, true, 0);
        hide_button_1.show_all();
        
        sbutton = new SerialButton();
        sbutton.insert(TRACKLIST_VIEW_NAME, SHOWTRACKLIST);
        sbutton.insert(VIDEOVIEW_NAME, SHOWVIDEO);
        sbutton.insert(LYRICS_VIEW_NAME, SHOWLYRICS);
        bottom_box.pack_start(sbutton, false, false, 0);
        sbutton.show_all();
        
        videovbox.show_all();
        inner_box.pack_start(bottom_box, false, false, 0);
        
        win.notify["media-browser-visible"].connect( (s, val) => {
            if(win.media_browser_visible == true) {
                hide_button_image.set_from_stock(  Gtk.Stock.GOTO_FIRST, Gtk.IconSize.MENU);
                hide_button_1.set_tooltip_text(  HIDE_LIBRARY);
            }
            else {
                hide_button_image.set_from_stock(  Gtk.Stock.GOTO_LAST, Gtk.IconSize.MENU);
                hide_button_1.set_tooltip_text(  SHOW_LIBRARY);
            }
        });
    }
}

public class Xnoise.VideoScreen : Gtk.DrawingArea {
    private static const string SELECT_EXT_SUBTITLE_FILE = _("Select external subtitle file");
    private const double MIN_BORDER_DIST = 10;
    private const double MAX_UPSCALE_RATIO = 2.0;
    private Gdk.Pixbuf logo_pixb;
    private Gdk.Pixbuf cover_image_pixb;
    private unowned Main xn;
    private bool cover_image_available;
    private Gtk.Menu? menu;
    private uint refresh_source = 0;
    private unowned GstPlayer player;
    private Gdk.Pixbuf? logo = null;
    private int w = 0;
    private int h = 0;
    private int y_offset = 0;
    private int x_offset = 0;
    private double ratio = 1.0;
    private int imageWidth;
    private int imageHeight;

    private Cairo.ImageSurface surface;

    public VideoScreen(GstPlayer player) {
        this.player = player;
        this.xn = Main.instance;
        rect = Gdk.Rectangle();
        init_video_screen();
        cover_image_available = false;
        global.notify["image-path-large"].connect(on_image_path_changed);
        global.notify["image-path-embedded"].connect(on_image_path_changed);
        this.button_release_event.connect(on_button_released);
        global.tag_changed.connect(on_tag_changed);
    }
    
    private void on_tag_changed() {
        if(refresh_source != 0)
            Source.remove(refresh_source);
        
        refresh_source = Timeout.add(300, () => {
            trigger_expose();
            refresh_source = 0;
            return false;
        });
    }
    
    private bool on_button_released(Gtk.Widget sender, Gdk.EventButton e) {
        if(!((e.button==3) && (e.type==Gdk.EventType.BUTTON_RELEASE))) {
            return false; //exit here, if it's no the button 3 single click release
        }
        else {
            menu = create_rightclick_menu();
            if(menu != null) 
                menu.popup(null, null, null, 0, e.time);
        }
        return true;
    }
    
    private Gtk.Menu? create_rightclick_menu() {
        Gtk.Menu rightmenu = null;
        int groupcnt = 0;
        if(player.available_subtitles != null) {
            if(rightmenu == null)
                rightmenu = new Gtk.Menu();
            if(player.available_subtitles.length > 0) {
                var menuitem = new ImageMenuItem.from_stock(Gtk.Stock.INDEX, null);
                menuitem.set_label(_("No Subtitle"));
                menuitem.activate.connect( () => { 
                    this.player.current_text = -2;
                });
                rightmenu.append(menuitem);
            }
            int i = 0;
            foreach(unowned string s in player.available_subtitles) {
                var menuitem = new ImageMenuItem.from_stock(Gtk.Stock.INDEX, null);
                menuitem.set_label(s);
                int k = i++;
                menuitem.activate.connect( () => { 
                    //print("text selected: %d\n", k); 
                    this.player.current_text = k;
                });
                rightmenu.append(menuitem);
            }
            if(player.available_subtitles.length > 1) // 1 is used for choosing no subtitles
                groupcnt++;
        }
        if(player.available_audiotracks != null && player.available_audiotracks.length > 1) {
            if(rightmenu == null)
                rightmenu = new Gtk.Menu();
            if(groupcnt > 0)
                rightmenu.append(new SeparatorMenuItem());
            int i = 0;
            foreach(unowned string s in player.available_audiotracks) {
                var menuitem = new ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
                menuitem.set_label(s);
                int k = i++;
                menuitem.activate.connect( () => { 
                    //print("audio selected: %d\n", k); 
                    this.player.current_audio = k;
                });
                rightmenu.append(menuitem);
            }
            if(player.available_audiotracks.length > 1)
                groupcnt++;
        }
        if(player.current_has_video_track) {
            if(rightmenu == null)
                rightmenu = new Gtk.Menu();
            if(groupcnt > 0)
                rightmenu.append(new SeparatorMenuItem());
            var menu_item = new ImageMenuItem.from_stock(Gtk.Stock.EDIT, null);
            menu_item.set_label(SELECT_EXT_SUBTITLE_FILE);
            menu_item.activate.connect(this.open_suburi_filechooser);
            rightmenu.append(menu_item);
        }
        if(rightmenu == null)
            rightmenu = new Gtk.Menu();
        else
            rightmenu.append(new SeparatorMenuItem());
        var fullscreenmenuitem = new ImageMenuItem.from_stock(
           (main_window.fullscreenwindowvisible ? Gtk.Stock.LEAVE_FULLSCREEN : Gtk.Stock.FULLSCREEN),
           null
        );
        fullscreenmenuitem.set_label(
           (main_window.fullscreenwindowvisible ? _("Leave Fullscreen") : _("Fullscreen"))
        );
        fullscreenmenuitem.activate.connect( () => { 
            main_window.toggle_fullscreen();
        });
        rightmenu.append(fullscreenmenuitem);
        if(rightmenu != null)
            rightmenu.show_all();
        return rightmenu;
    }
    
    private void open_suburi_filechooser() {
        Gtk.FileChooserDialog fcdialog = new Gtk.FileChooserDialog(
            SELECT_EXT_SUBTITLE_FILE,
            main_window,
            Gtk.FileChooserAction.OPEN,
            Gtk.Stock.CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.Stock.OPEN,
            Gtk.ResponseType.ACCEPT,
            null);
        fcdialog.set_current_folder(Environment.get_home_dir());
        if(fcdialog.run() == Gtk.ResponseType.ACCEPT) {
            File f = File.new_for_path(fcdialog.get_filename());
            //print("got suburi xxx : %s\n", f.get_uri());
            player.set_subtitle_uri(f.get_uri());
        }
        fcdialog.destroy();
        fcdialog = null;
    }

    private void on_image_path_changed() {
        //print("on_image_path_changed %s\n", global.image_path_embedded);
        if(global.image_path_embedded != null) {
            try {
                cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_embedded);
            }
            catch(GLib.Error e) {
                print("%s\n", e.message);
                return;
            }
            cover_image_available = true;
            if(this.visible) {
                Gdk.Window w = this.get_window();
                if(w != null) 
                    w.invalidate_rect(null, false);
            }
        }
        else if(global.image_path_large != null) {
            try {
                cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_large);
            }
            catch(GLib.Error e) {
                print("%s\n", e.message);
                return;
            }
            cover_image_available = true;
            if(this.visible) {
                Gdk.Window w = this.get_window();
                if(w != null) 
                    w.invalidate_rect(null, false);
            }
        }
        else {
            cover_image_pixb = null;
            cover_image_available = false;
            Idle.add(() => {
                trigger_expose();
                return false;
            });
        }
    }
    
    private void init_video_screen() {
        this.set_double_buffered(false);
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK |
                        Gdk.EventMask.ENTER_NOTIFY_MASK);
        try {
            logo_pixb = new Gdk.Pixbuf.from_file(Config.XN_UIDIR + "xnoise_bruit.svg");
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
        }
    }
    
    private Gdk.Rectangle rect;
    private const int frame_width = 1;
    
    public override bool draw(Cairo.Context cr) {
        w = this.get_allocated_width();
        h = this.get_allocated_height();
            
        if(!gst_player.current_has_video_track) {
            if(!cover_image_available) {
                cr.set_source_rgb(0.0f, 0.0f, 0.0f);
                cr.rectangle(0, 0, get_allocated_width(), get_allocated_height());
                cr.fill();
                if(logo_pixb == null)
                    try {
                        logo_pixb = new Gdk.Pixbuf.from_file(Config.XN_UIDIR + "xnoise_bruit.svg");
                    }
                    catch(Error e) {
                        print("%s\n", e.message);
                        return true;
                    }
                logo = logo_pixb.scale_simple((int)(logo_pixb.get_width() * 0.8),
                                              (int)(logo_pixb.get_height() * 0.8),
                                              Gdk.InterpType.HYPER);
                y_offset = (int)((h * 0.5) - (logo.get_height() * 0.4));
                x_offset = (int)((w  * 0.5) - (logo.get_width()  * 0.4));
                Gdk.cairo_set_source_pixbuf(cr, logo, x_offset, y_offset);
                cr.paint();
                return true;
            }
            else {
                logo = cover_image_pixb;
                if(logo == null)
                    return true;
                
                this.imageWidth  = logo.get_width();
                this.imageHeight = logo.get_height();
                
                if((double) w/((2 * imageWidth) + MIN_BORDER_DIST) > (double) h/((1.5 * imageHeight) + MIN_BORDER_DIST))
                    ratio = (double) h/((1.5 * imageHeight) + MIN_BORDER_DIST);
                else
                    ratio = (double) w/((2 * imageWidth) + MIN_BORDER_DIST);
                
                ratio = double.min(ratio, MAX_UPSCALE_RATIO);
                //print("ratio : %lf\n", ratio);
                
                imageWidth  = (int)(imageWidth  * ratio);
                imageHeight = (int)(imageHeight * ratio);
                
                if(imageWidth <= 1 || imageHeight <= 1) {
                    // Do not paint for small pictures
                    return true;
                }
                logo = logo.scale_simple(imageWidth  - 2 * frame_width,
                                         imageHeight - 2 * frame_width,
                                         Gdk.InterpType.HYPER);
                
                y_offset = (int)((h * 0.45)  - (imageHeight * 0.5));
                x_offset = (int)((w  * 0.45));
                
                this.surface = new ImageSurface(0, imageWidth, imageHeight);
                Cairo.Context ct = new Cairo.Context(surface);
                ct.set_source_rgb(0.8, 0.8, 0.8);
                ct.set_line_width(0);
                ct.rectangle(0, 0, imageWidth, imageWidth);
                ct.fill();
                Gdk.cairo_set_source_pixbuf(ct, logo, frame_width, frame_width);
                ct.paint(); // paint on external context
                
                cr.paint(); // black background
                
                cr.translate(x_offset, y_offset);
                
                cr.set_source_surface(this.surface, 0, 0);
                cr.paint();
                cr.save();
                
                cr.move_to(-(x_offset), imageHeight/3.0);
                var font_description = new Pango.FontDescription();
                font_description.set_family(font_family);
                font_description.set_size((int)(font_size * Pango.SCALE));
                
                layout_width  = (int) (x_offset - (2 * MIN_BORDER_DIST));
                var pango_layout = Pango.cairo_create_layout(cr);
                pango_layout.set_font_description(font_description);
                pango_layout.set_width( (int)(layout_width  * Pango.SCALE));
                pango_layout.set_alignment(Pango.Alignment.RIGHT);
                pango_layout.set_markup(get_content_text() , -1);
                
                cr.set_source_rgb(0.9, 0.9, 0.9); // light gray font color
                Pango.cairo_show_layout(cr, pango_layout);
                cr.restore();
                
                double alpha = 0.35;
                double step = 1.3 * (1.0 / this.imageHeight);
                
                cr.translate(0.0, 2.0 * this.imageHeight);
                cr.scale(1, -1);
                
                for(int i = 0; i < imageHeight; i++) {
                    cr.rectangle(0, this.imageHeight - i, this.imageWidth, 1);
                    cr.save();
                    cr.clip();
                    cr.set_source_surface(this.surface, 0, 0);
                    alpha = alpha - step;
                    alpha = double.max(0.0, alpha);
                    cr.paint_with_alpha(alpha);
                    cr.restore();
                }
            }
        }
        return true;
    }
    
    private string get_content_text() {
        string result = EMPTYSTRING;
        string? uri = global.current_uri;
        
        string? title = global.current_title;
        string? artist = global.current_artist;
        string? album = global.current_album;
    
        string? filename = null;
        if(uri != null) {
            File f = File.new_for_uri(uri);
            if(f != null) {
                filename = f.get_basename();
                filename = Markup.escape_text(filename);
            }
        }
        //todo: handle streams, change label layout, pack into a box with padding and use Tooltip.set_custom
        if((title == null && artist == null && filename != null) || (filename == title)) {
            result = "";//"<b>" + prepare_name_from_filename(filename) + " </b>";
        }
        else {
            if(album == null)
                album = UNKNOWN_ALBUM_LOCALIZED;
            if(artist == null)
                artist = UNKNOWN_ARTIST_LOCALIZED;
            if(title == null)
                title = UNKNOWN_TITLE_LOCALIZED;
            
            album = Markup.escape_text(album);
            artist = Markup.escape_text(artist);
            title = Markup.escape_text(title);
            
            result = "<span size=\"large\" rise=\"8000\" weight=\"bold\">" + 
                      title +   "</span>\n" +
                      "<span size=\"small\" weight=\"light\" style=\"italic\">%s  </span>".printf(_("by")) +
                      artist + "\n" +
                      "<span size=\"small\" weight=\"light\" style=\"italic\">%s  </span> ".printf(_("on")) +
                      album;
        }
        return (owned)result;
    }
    

    public string font_family    { get; set; default = "Sans"; }
    public double font_size      { get; set; default = 15; }
    public string text           { get; set; }
    
    private int layout_width     = 100;
    private int layout_height    = 100;

    public void trigger_expose() {
        this.queue_draw();
    }
}


