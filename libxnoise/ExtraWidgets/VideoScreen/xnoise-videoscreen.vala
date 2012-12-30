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
    
    public VideoViewWidget(MainWindow win) {
        GLib.Object(orientation:Orientation.VERTICAL, spacing:0);
        this.win = win;
        setup_widgets();
    }
    
    public string get_view_name() {
        return VIDEOVIEW_NAME;
    }
    
    private void setup_widgets() {
        this.videovbox = new Box(Orientation.VERTICAL, 0);
        this.videoscreen = gst_player.videoscreen;
        videovbox.pack_start(videoscreen, true ,true ,0);
        this.pack_start(videovbox, true, true, 0);
    }
}

public class Xnoise.VideoScreen : Gtk.DrawingArea {
    private static const string SELECT_EXT_SUBTITLE_FILE = _("Select external subtitle file");
    private const double MIN_BORDER_DIST = 10;
    private const double MAX_UPSCALE_RATIO = 2.0;
    private Gdk.Pixbuf default_image;
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
        int ev = this.get_events();
        this.set_events(ev|Gdk.EventMask.SCROLL_MASK);
        this.button_release_event.connect(on_button_released);
        this.scroll_event.connect(this.on_scrolled);
        global.tag_changed.connect(on_tag_changed);
    }
    
    private bool on_scrolled(Gdk.EventScroll event) {
        if(event.direction == Gdk.ScrollDirection.DOWN) {
            double tmp = player.volume - 0.02;
            player.volume = double.max(0.0, tmp);
        }
        else if(event.direction == Gdk.ScrollDirection.UP) {
            double tmp = player.volume + 0.02;
            player.volume = double.min(1.0, tmp);
        }
        return false;
    }
    
    private void on_tag_changed() {
        if(refresh_source != 0)
            Source.remove(refresh_source);
        
        refresh_source = Timeout.add(500, () => {
            var job = new Worker.Job(Worker.ExecutionType.ONCE, this.load_image_from_path_job);
            io_worker.push_job(job);
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
        if(refresh_source != 0)
            Source.remove(refresh_source);
        
        refresh_source = Timeout.add(500, () => {
            var job = new Worker.Job(Worker.ExecutionType.ONCE, this.load_image_from_path_job);
            io_worker.push_job(job);
            refresh_source = 0;
            return false;
        });
    }
    
    private bool load_image_from_path_job(Worker.Job job) {
        if(global.image_path_embedded != null) {
            try {
                cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_embedded);
            }
            catch(GLib.Error e) {
                cover_image_available = false;
                cover_image_pixb = null;
                return false;
            }
            cover_image_available = true;
            Idle.add(() => {
                queue_draw();
                return false;
            });
        }
        else if(global.image_path_large != null) {
            try {
                cover_image_pixb = new Gdk.Pixbuf.from_file(global.image_path_large);
            }
            catch(GLib.Error e) {
                cover_image_available = false;
                cover_image_pixb = null;
                return false;
            }
            cover_image_available = true;
            Idle.add(() => {
                queue_draw();
                return false;
            });
        }
        else {
            cover_image_pixb = null;
            cover_image_available = false;
            Idle.add(() => {
                trigger_expose();
                return false;
            });
        }
        return false;
    }
    
    private void init_video_screen() {
        this.set_double_buffered(false);
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK |
                        Gdk.EventMask.ENTER_NOTIFY_MASK);
        try {
            default_image = new Gdk.Pixbuf.from_file(Config.XN_UIDIR + "xnoise_bruit.svg");
        }
        catch(GLib.Error e) {
            print("%s\n", e.message);
            return;
        }
        default_image = default_image.scale_simple((int)(default_image.get_width()  * 0.8),
                                                   (int)(default_image.get_height() * 0.8),
                                                   Gdk.InterpType.HYPER);
    }
    
    private Gdk.Rectangle rect;
    private const int frame_width = 1;
    
    public override bool draw(Cairo.Context cr) {
        w = this.get_allocated_width();
        h = this.get_allocated_height();
            
        if(!gst_player.current_has_video_track) {
            if(!cover_image_available || cover_image_pixb == null) {
                cr.set_source_rgb(0.0f, 0.0f, 0.0f);
                cr.rectangle(0, 0, get_allocated_width(), get_allocated_height());
                cr.fill();
                y_offset = (int)((h * 0.5)  - (default_image.get_height() * 0.4));
                x_offset = (int)((w  * 0.5) - (default_image.get_width()  * 0.4));
                Gdk.cairo_set_source_pixbuf(cr, default_image, x_offset, y_offset);
                cr.paint();
                return true;
            }
            else {
                logo = cover_image_pixb;
                if(logo == null)
                    return true;
                
                this.imageWidth  = logo.get_width();
                this.imageHeight = logo.get_height();
                
                if((double) w/((2 * imageWidth) + MIN_BORDER_DIST) > 
                    (double) h/((1.5 * imageHeight) + MIN_BORDER_DIST))
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
                logo = cover_image_pixb.scale_simple(imageWidth  - 2 * frame_width,
                                                     imageHeight - 2 * frame_width,
                                                     Gdk.InterpType.HYPER);
                
                y_offset = (int)((h * 0.45)  - (imageHeight * 0.5));
                x_offset = (int)((w  * 0.45));
                
                this.surface = new ImageSurface(0, imageWidth, imageHeight);
                Cairo.Context extra_context = new Cairo.Context(surface);
                extra_context.set_source_rgb(0.8, 0.8, 0.8);
                extra_context.set_line_width(0);
                extra_context.rectangle(0, 0, imageWidth, imageWidth);
                extra_context.fill();
                Gdk.cairo_set_source_pixbuf(extra_context, logo, frame_width, frame_width);
                extra_context.paint(); // paint on external context
                
                cr.paint(); // black background
                
                cr.translate(x_offset, y_offset);
                
                cr.set_source_surface(this.surface, 0, 0);
                cr.paint();
                cr.save();
                
                cr.move_to(-(x_offset) + MIN_BORDER_DIST, imageHeight/3.0);
                var font_description = new Pango.FontDescription();
                font_description.set_family(font_family);
                font_description.set_size((int)(font_size * Pango.SCALE));
                
                layout_width  = (int) (x_offset - (3 * MIN_BORDER_DIST));
                var pango_layout = Pango.cairo_create_layout(cr);
                pango_layout.set_font_description(font_description);
                pango_layout.set_width( (int)(layout_width  * Pango.SCALE));
                pango_layout.set_alignment(Pango.Alignment.RIGHT);
                pango_layout.set_markup(get_content_text() , -1);
                
                cr.set_source_rgb(0.9, 0.9, 0.9); // light gray font color
                Pango.cairo_show_layout(cr, pango_layout);
                cr.restore();
                
                double alpha = 0.2;
                double step = 0.5 * (1.0 / this.imageHeight);
                
                cr.translate(0.0, 2.0 * this.imageHeight + 3);
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

    public void trigger_expose() {
        this.queue_draw();
    }
}


