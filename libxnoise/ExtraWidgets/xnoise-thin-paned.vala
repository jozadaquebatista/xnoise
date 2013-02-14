/*
 * xnoise-thin-paned.vala
 */

/*
 * Copyright (c) 2012 Victor Eduardo <victoreduardm@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 *
 * 2013 File modified for xnoise by Jörn Magens <shuerhaaken@googlemail.com>
 *
 */



using Gtk;

using Xnoise;


private class Xnoise.ThinPaned : Gtk.Paned {
    private const string STYLE_PROP_OVERLAY_HANDLE_SIZE = "overlay-handle-size";
    private Gdk.Window overlay_handle;
    private bool in_resize = false;
    
    private const string DEFAULT_STYLESHEET = """
        XnoiseThinPaned { -GtkPaned-handle-size: 1px; }
    """;
    private const string FALLBACK_STYLESHEET = """
        XnoiseThinPaned.sidebar-pane-separator {
            background-color: alpha(#000, 0.2);
            border-width: 0;
        }
    """;
    
    
    public ThinPaned() {
        set_theming(this, DEFAULT_STYLESHEET, null, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        set_theming(this, FALLBACK_STYLESHEET, null, Gtk.STYLE_PROVIDER_PRIORITY_THEME);
    }
    
    
    private Gtk.CssProvider? set_theming(Gtk.Widget widget, string stylesheet,
                                         string? class_name, int priority) {
        var css_provider = get_css_provider(stylesheet);
        var context = widget.get_style_context();
        if(css_provider != null)
            context.add_provider(css_provider, priority);
        if(class_name != null && class_name.strip() != "")
            context.add_class(class_name);
        return css_provider;
    }
    
    private bool is_left_to_right(Gtk.Widget widget) {
        var dir = widget.get_direction();
        if(dir == Gtk.TextDirection.NONE)
            dir = Gtk.Widget.get_default_direction();
        return dir == Gtk.TextDirection.LTR;
    }

    private Gtk.CssProvider? get_css_provider(string stylesheet) {
        Gtk.CssProvider provider = new Gtk.CssProvider();
        try {
            provider.load_from_data(stylesheet, -1);
        }
        catch(Error e) {
            warning("Could not create CSS Provider: %s\nStylesheet:\n%s",
                     e.message, stylesheet);
            return null;
        }
        return provider;
    }

    public unowned Gdk.Window get_overlay_handle_window() {
        return overlay_handle;
    }

    public override void realize() {
        base.realize();
        // Create invisible overlay handle
        var attributes = Gdk.WindowAttr();
        attributes.window_type = Gdk.WindowType.CHILD;
        attributes.x = 0;
        attributes.y = 0;
        attributes.width = 0;
        attributes.height = 0;
        attributes.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
        attributes.event_mask = Gdk.EventMask.BUTTON_PRESS_MASK
                              | Gdk.EventMask.BUTTON_RELEASE_MASK
                              | Gdk.EventMask.ENTER_NOTIFY_MASK
                              | Gdk.EventMask.LEAVE_NOTIFY_MASK
                              | Gdk.EventMask.POINTER_MOTION_MASK
                              | Gdk.EventMask.POINTER_MOTION_HINT_MASK;
        var attributes_mask = Gdk.WindowAttributesType.X
                            | Gdk.WindowAttributesType.Y
                            | Gdk.WindowAttributesType.CURSOR;
        overlay_handle = new Gdk.Window(get_window(), attributes, attributes_mask);
        overlay_handle.set_user_data(this); // forward the gtk events to this widget
        update_overlay_handle();
    }

    public override void unrealize() {
        base.unrealize();
        overlay_handle.set_user_data(null);
        overlay_handle.destroy();
        overlay_handle = null;
    }

    public override void map() {
        base.map();
        overlay_handle.show();
    }

    public override void unmap() {
        base.unmap();
        overlay_handle.hide();
    }

    public override bool draw(Cairo.Context cr) {
        base.draw(cr);
        if(!overlay_handle.is_visible())
            return false;
        Gtk.Allocation allocation;
        get_allocation(out allocation);
        StyleContext context = get_style_context();
        var state = context.get_state();
        if(is_focus)
            state |= Gtk.StateFlags.SELECTED;
        if(in_resize)
            state |= Gtk.StateFlags.PRELIGHT;
        double width, height;
        if(orientation == Gtk.Orientation.HORIZONTAL) {
            width = 1;
            height = allocation.height;
        }
        else {
            width = allocation.width;
            height = 1;
        }
        cr.save();
        Gtk.cairo_transform_to_window(cr, this, get_handle_window());
        // render normal background to override default handle.
        context.render_background(cr, 0, 0, width, height);
        
        context.save();
        context.add_class("sidebar-pane-separator");
        context.set_state(state);
        // draw thin separator. We don't use render_handle() because we're
        // only supposed to draw a thin separator without any marks.
        context.render_background(cr, 0, 0, width, height);
        context.restore();
        cr.restore();
        return false;
    }

    public override void size_allocate(Gtk.Allocation allocation) {
        base.size_allocate(allocation);
        update_overlay_handle();
    }

    private void update_overlay_handle() {
        if(overlay_handle == null || !get_realized())
            return;
        int overlay_handle_x, overlay_handle_y, overlay_handle_width, overlay_handle_height;
        var default_handle = get_handle_window();
        default_handle.get_position(out overlay_handle_x, out overlay_handle_y);
        overlay_handle_width = default_handle.get_width();
        overlay_handle_height = default_handle.get_height();
        int overlay_handle_size = 10;
        if(orientation == Gtk.Orientation.HORIZONTAL) {
            overlay_handle_x -= overlay_handle_size / 2;
            overlay_handle_width += overlay_handle_size;
        }
        else {
            overlay_handle_y -= overlay_handle_size / 2;
            overlay_handle_height += overlay_handle_size;
        }
        overlay_handle.move_resize(overlay_handle_x,
                                    overlay_handle_y,
                                    overlay_handle_width,
                                    overlay_handle_height);
        state_flags_changed(0); // Updates the handle's cursor
        if(get_mapped() && default_handle.is_visible())
            overlay_handle.show();
        else
            overlay_handle.hide();
    }

    public override void state_flags_changed(Gtk.StateFlags previous_state) {
        base.state_flags_changed(previous_state);
        if(get_realized()) {
            var default_handle_cursor = get_handle_window().get_cursor();
            if(overlay_handle.get_cursor() != default_handle_cursor)
                overlay_handle.set_cursor(default_handle_cursor);
        }
    }

    public override bool motion_notify_event(Gdk.EventMotion event) {
        if(!in_resize)
            return base.motion_notify_event(event);
        var device = event.device ?? Gtk.get_current_event_device();
        if(device == null) {
            var display = get_display();
            if(display != null) {
                var dev_manager = display.get_device_manager();
                if(dev_manager != null)
                    device = dev_manager.list_devices(Gdk.DeviceType.MASTER).nth_data(0);
            }
        }
        if(device != null) {
            int x, y, pos = 0;
            get_window().get_device_position(device, out x, out y, null);
            if(orientation == Gtk.Orientation.HORIZONTAL)
                pos = is_left_to_right(this) ? x : get_allocated_width() - x;
            else
                pos = y;
            position = pos.clamp(min_position, max_position);
            return true;
        }
        return_val_if_reached(false);
    }

    public override bool button_press_event(Gdk.EventButton event) {
        if(!in_resize && event.button == Gdk.BUTTON_PRIMARY && event.window == overlay_handle) {
            in_resize = true;
            Gtk.grab_add(this);
            return true;
        }
        return base.button_press_event(event);
    }

    public override bool button_release_event(Gdk.EventButton event) {
        if(event.window == overlay_handle) {
            in_resize = false;
            Gtk.grab_remove(this);
            return true;
        }
        return base.button_release_event(event);
    }

    public override bool grab_broken_event(Gdk.EventGrabBroken event) {
        in_resize = false;
        return base.grab_broken_event(event);
    }
}

