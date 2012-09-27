/* xnoise-plugin-switch-widget.vala
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
 *     Jörn Magens <shuerhaaken@googlemail.com>
 */

using Gtk;

using Xnoise;

private class Xnoise.PluginSwitch : Gtk.Box {
    private string plugin_name;
    private Gtk.Switch pswitch;
    private weak PluginModule.Container pc = null;
    private Gtk.SizeGroup label_sizegroup;
    
    public PluginCategory plugin_category { 
        get { return pc.info.category; }
    }
    
    public signal void sign_plugin_activestate_changed(string name);
    
    
    public PluginSwitch(string plugin_name, Gtk.SizeGroup label_sizegroup) {
        GLib.Object(orientation:Orientation.HORIZONTAL,spacing:0);
        this.plugin_name = plugin_name;
        this.label_sizegroup = label_sizegroup;
        
        assert(get_plugin_reference());
        
        create_widgets();
        init_value();
        connect_signals();
        
        this.show_all();
    }
    
    
    private void init_value() {
        this.pswitch.set_active(pc.activated);
    }
    
    private void connect_signals() {
        if(pc == null)
            return;
        pc.sign_activated.connect( () => {
            print("p sign act switch\n");
            this.pswitch.freeze_notify();
            this.pswitch.set_active(true);
            this.pswitch.thaw_notify();
        });
        pc.sign_deactivated.connect( () => {
            print("p sign deact switch\n");
            this.pswitch.freeze_notify();
            this.pswitch.set_active(false);
            this.pswitch.thaw_notify();
        });
    }
    
    private bool get_plugin_reference() {
        pc = plugin_loader.plugin_htable.lookup(this.plugin_name);
        if(pc == null)
            return false;
        return true;
    }
    
    private void create_widgets() {
        var label = new Gtk.Label(pc.info.pretty_name);
        label.set_alignment(0.0f, 0.5f);
        label.justify = Justification.LEFT;
        label.xpad = 6;
        label.set_line_wrap_mode(Pango.WrapMode.WORD);
        label.set_line_wrap(true);
        this.pack_start(label, false, false, 0);
        pswitch = new Gtk.Switch();
        pswitch.margin_left = 2;
        var bx = new Box(Orientation.VERTICAL, 0);
        bx.pack_start(new DrawingArea(), false, true, 0);
        bx.pack_start(pswitch, false, false, 0);
        bx.pack_start(new DrawingArea(), false, true, 0);
        this.pack_start(bx, false, false, 0);
        label_sizegroup.add_widget(label);
        pswitch.notify["active"].connect( () => {
            if(pswitch.get_active()) {
                plugin_loader.activate_single_plugin(plugin_name);
                sign_plugin_activestate_changed(plugin_name);
            }
            else {
                plugin_loader.deactivate_single_plugin(plugin_name);
                sign_plugin_activestate_changed(plugin_name);
            }
        });
        this.set_tooltip_markup(Markup.printf_escaped("%s", pc.info.description));
    }
}

