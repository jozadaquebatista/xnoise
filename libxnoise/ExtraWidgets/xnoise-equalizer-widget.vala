/* xnoise-equalizer-widget.vala
 *
 * Copyright(C) 2013 Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
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

using Gst;
using Gtk;

using Xnoise;


private class Xnoise.EqualizerWidget : Gtk.Box {
    private unowned GstEqualizer equalizer;
    
    private EqualizerScale[] scale_indies = new EqualizerScale[10];
    
    public Button closebutton; 
    private Gtk.Scale preamp;
    
    internal bool eq_active {get; set;}
    
    private class EqualizerScale : Gtk.Box {
        private Gtk.Scale scale;
        private int idx;
        private int frequency;
        private unowned GstEqualizer equalizer;
        private EqualizerWidget eq_widget;
        
        public signal void value_changed(int index, double new_val);
        
        public EqualizerScale(EqualizerWidget eq_widget, GstEqualizer equalizer, int idx, int frequency) {
            GLib.Object(orientation:Orientation.VERTICAL,spacing:5);
            this.eq_widget = eq_widget;
            this.equalizer = equalizer;
            this.idx = idx;
            this.frequency = frequency;
            
            setup_widgets();
        }
        
        private void on_value_changed(Gtk.Range sender) {
            this.equalizer[idx] = (double)scale.get_value();
            this.value_changed(idx, (double)scale.get_value());
            if(eq_widget.eq_active)
                Params.set_double_value("eq_band%d".printf(idx), scale.get_value());
        }
        
        public void restore() {
            scale.set_value(Params.get_double_value("eq_band%d".printf(idx)));
        }
        
        public void set_gain(double gain) {
            scale.set_value(gain);
        }
        
        private void setup_widgets() {
            // allow +/- 90%
            scale = new Scale.with_range(Orientation.VERTICAL, -85, 85, 1);
            scale.can_focus = false;
            scale.inverted = true;
            scale.draw_value = false;
            scale.add_mark(0, PositionType.LEFT, null);
            scale.set_value(this.equalizer[idx]); // initialize
            scale.value_changed.connect(on_value_changed);
            this.pack_start(scale, true, true, 0);
            
            double f = (double)frequency;
            var l = new Label("");
            if(f / 1000.0 > 1.0)
                l.label = "%.1lfk".printf(f/1000.0).replace(",", ".");
            else if(f / 1000.0 == 1.0)
                l.label = "%.0lfk".printf(f/1000.0).replace(",", ".");
            else
                l.label = "%d".printf((int)f);
            l.set_alignment(0.8f, 0.6f);
            this.pack_start(l, false, false, 0);
            this.show_all();
            
            this.scale.sensitive = eq_widget.eq_active;
            eq_widget.notify["eq-active"].connect( () => {
                this.scale.sensitive = eq_widget.eq_active;
            });
        }
    }
    
    public EqualizerWidget(GstEqualizer equalizer) {
        GLib.Object(orientation:Orientation.VERTICAL,spacing:5);
        this.equalizer = equalizer;
        setup_widgets();
    }
    
    ~EqualizerWidget() {
        //print("dtor EqualizerWidget\n");
    }

    private bool in_load_preset = false;
    private void on_preset_changed(ComboBox sender) {
        GstEqualizer.TenBandPreset pres;
        EqualizerScale sc;
        if(!eq_active) {
            pres = equalizer.get_preset(0);
            in_load_preset = true;
            for(int j = 0; j < 10; j++) {
                sc = scale_indies[j];
                sc.set_gain(pres.freq_band_gains[j]);
                equalizer[j] = pres.freq_band_gains[j];
            }
            preamp.set_value(pres.pre_gain);
            Idle.add(() => {
                in_load_preset = false;
                return false;
            });
            return;
        }
        string s = sender.get_active_id();
        if(s == "")
            return;
        Params.set_string_value("eq_combo", s);
        if(s == "1") //custom
            return;
        int i = int.parse(s);
        //print("seleted preset %d\n", i);
        pres = equalizer.get_preset(i);
        in_load_preset = true;
        for(int j = 0; j < 10; j++) {
            sc = scale_indies[j];
            sc.set_gain(pres.freq_band_gains[j]);
            equalizer[j] = pres.freq_band_gains[j];
        }
        preamp.set_value(pres.pre_gain);
        Idle.add(() => {
            in_load_preset = false;
            return false;
        });
    }
    
    private void on_eq_scale_value_changed(EqualizerScale sender, int idx, double val) {
        if(in_load_preset)
            return;
        c.set_active_id("1"); // set to custom
    }
    
    private void on_preamp_changed(Gtk.Range sender) {
        gst_player.preamplification = (double)preamp.get_value();
        if(eq_active)
            Params.set_double_value("preamp", (double)preamp.get_value());
        if(in_load_preset)
            return;
        c.set_active_id("1"); // set to custom
    }
    
    private ComboBoxText c;
    private Gtk.Switch on_off_switch;
    
    private void setup_widgets() {
        var combox = new Gtk.Box(Orientation.HORIZONTAL, 0);
        c = new ComboBoxText();
        for(int i = 0; i < equalizer.preset_count(); i++) {
            GstEqualizer.TenBandPreset pres = null;
            pres = equalizer.get_preset(i);
            c.append(i.to_string(), pres.name);
        }
        if(Params.get_string_value("eq_combo") != "")
            c.set_active_id(Params.get_string_value("eq_combo"));
        else
            c.set_active_id("0");
        
        c.changed.connect(on_preset_changed);
        
        var vbox_switch = new Gtk.Box(Orientation.VERTICAL, 0);
        on_off_switch = new Gtk.Switch();
        vbox_switch.pack_start(on_off_switch, false, false, 0);
        vbox_switch.pack_start(new DrawingArea(), false, false, 0);
        combox.pack_start(vbox_switch, false, false, 0);
        eq_active = !Params.get_bool_value("not_use_eq");
        on_off_switch.set_active(eq_active);
        on_off_switch.notify["active"].connect( () => {
            if(!on_off_switch.active) {
                Params.set_bool_value("not_use_eq", true);
                eq_active = false;
            }
            else {
                Params.set_bool_value("not_use_eq", false);
                eq_active = true;
            }
        });
        var l = new Label("");
        combox.pack_start(l, true, true, 0);
        l = new Label(_("Preset:"));
        combox.pack_start(l, false, false, 0);
        combox.pack_start(c, false, false, 0);
        this.pack_start(combox, false, false, 0);
        var freq_gains_box = new Gtk.Box(Orientation.HORIZONTAL, 3);
        int[] fa;
        equalizer.get_frequencies(out fa);
        assert(fa.length == 10);
        
        //Preamp
        var preampbox = new Gtk.Box(Orientation.VERTICAL, 5);
        preamp = new Scale.with_range(Orientation.VERTICAL, 0, 3, 0.05);
        preamp.can_focus = false;
        preamp.inverted = true;
        preamp.draw_value = false;
        preamp.add_mark(1, PositionType.LEFT, null);
        preamp.set_value(gst_player.preamplification);
        preamp.value_changed.connect(on_preamp_changed);
        preampbox.pack_start(preamp, true, true, 0);
        var l_pre = new Label(_("Volume"));
        preampbox.pack_start(l_pre, false, false, 0);
        freq_gains_box.pack_start(preampbox, true, true, 10);
        
        preamp.sensitive = eq_active;
        c.sensitive      = eq_active;
        
        this.notify["eq-active"].connect( () => {
            preamp.sensitive = eq_active;
            c.sensitive      = eq_active;
            if(eq_active) {
                for(int i = 0; i < 10; i++) {
                    scale_indies[i].restore();
                }
                preamp.set_value(Params.get_double_value("preamp"));
            }
            on_preset_changed(c);
        });
        
        Idle.add(() => {
            if(eq_active) {
                preamp.set_value(
                    Params.get_double_value("preamp") < 0.05 ? 1.0 : Params.get_double_value("preamp")
                );
            }
            else {
                preamp.set_value(1.0);
            }
            return false;
        });
        for(int i = 0; i < 10; i++) {
            var esc = new EqualizerScale(this, equalizer, i, fa[i]);
            freq_gains_box.pack_start(esc, true, true, 0);
            scale_indies[i] = esc;
            esc.value_changed.connect(on_eq_scale_value_changed);
        }
        this.pack_start(freq_gains_box, true, true, 0);
        closebutton = new Button.from_stock(Stock.CLOSE);
        var closebx = new Box(Orientation.HORIZONTAL, 0);
        closebx.pack_start(new Label(""), true, true, 2);
        closebx.pack_start(closebutton, false, false, 0);
        this.pack_start(closebx, false, false, 2);
        this.set_size_request(450, 250);
        this.border_width = 5;
        this.show_all();
    }
}


