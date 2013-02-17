/* xnoise-app-menu-button.vala
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

private class Xnoise.AppMenuButton : Gtk.ToolItem {
    private uint button_press_src = 0;
    private uint deactivtion_src = 0;
    private Gtk.ToggleButton? content;
    private Gtk.Menu menu;
    private Image img;
    
    public AppMenuButton(Gtk.Menu menu, string? tooltip_text = null) {
//        var box = new Gtk.Box(Orientation.VERTICAL, 0);
        content = new Gtk.ToggleButton();
        content.set_relief(ReliefStyle.NORMAL);
//        var eb = new Gtk.EventBox();
//        eb.visible_window = false;
//        box.pack_start(eb, true, true, 0);
//        box.pack_start(content, false, false, 0);
//        eb = new Gtk.EventBox();
//        eb.visible_window = false;
//        box.pack_start(eb, true, true, 0);
        this.add(content);
        
        unowned IconTheme theme = IconTheme.get_default();
        
        // use standard icon theme or local fallback
        if(theme.has_icon("emblem-system-symbolic"))
            img = IconRepo.get_themed_image_icon("emblem-system-symbolic",
                                                 IconSize.LARGE_TOOLBAR);
        else
            img = IconRepo.get_themed_image_icon("xn-emblem-system-symbolic",
                                                 IconSize.LARGE_TOOLBAR);
        
        content.add(img);
//        this.set_icon_widget(img);
        img.show();
        
        this.menu = menu;
        
        if(tooltip_text != null)
            this.set_tooltip_text(tooltip_text);
        
        if(this.menu.get_attach_widget() != null)
            this.menu.detach();
        
        this.menu.attach_to_widget(this.content, null);
        
//        this.content = this.get_child() as Gtk.Button;
//        assert(content != null);
        
//        this.content.set_relief(Gtk.ReliefStyle.HALF);
        this.content.events |=
           Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK;
        
        this.content.button_press_event.connect(on_button_pressed);
        this.content.button_release_event.connect(on_button_released);
        
        this.menu.deactivate.connect( () => {
            if(deactivtion_src != 0)
                Source.remove(deactivtion_src);
            
            deactivtion_src = Idle.add( () => {
                this.content.active = false;
                menu.popdown();
                deactivtion_src = 0;
                return false;
            });
        });
        this.show_all();
    }

    private bool on_button_pressed(Gdk.EventButton e) {
        if(e.button != 1)
            return true;
        
        if(button_press_src != 0)
            Source.remove(button_press_src);
        
        button_press_src = Idle.add( () => {
            button_press_src = 0;
            this.content.active = true;
            menu.popup(null, null, position_menu, e.button, (e.time == 0 ? get_current_event_time() : e.time));
            return false;
        });
        return true;
    }

    private bool on_button_released(Gdk.EventButton e) {
        if(e.button != 1)
            return true;
        
        if(button_press_src != 0) {
            Source.remove(button_press_src);
            button_press_src = 0;
        }
        this.content.active = true;
        menu.popup(null, null, position_menu, e.button, (e.time == 0 ? get_current_event_time() : e.time));
        if(menu.attach_widget != null)
            menu.attach_widget.set_state_flags(StateFlags.SELECTED, true);
        return true;
    }

    private void position_menu(Gtk.Menu menu, out int x, out int y, out bool push) {
        int w;
        int h;
        Allocation widget_allocation;
        Allocation menu_allocation;
        
        menu.get_allocation(out menu_allocation);
        push = true;
        if(menu.attach_widget == null || menu.attach_widget.get_window() == null) {
            x = y = 0;
            return;
        }
        menu.attach_widget.get_window().get_origin(out x, out y);
        menu.attach_widget.get_allocation(out widget_allocation);
        
        //TODO: test for RTL
        x += widget_allocation.x;
        x += widget_allocation.width;
        x -= menu_allocation.width;
        
        menu.get_size_request(out w, out h);
        y += widget_allocation.y;
        if(y + h >= menu.attach_widget.get_screen().get_height())
            y -= h;
        else
            y += widget_allocation.height;
    }

    public override void show_all() {
        menu.show_all();
        base.show_all();
    }
}
