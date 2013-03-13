/* xnoise-gst-equalizer.vala
 *
 * Copyright(C) 2012 Jörn Magens
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

using Xnoise;


private class Xnoise.GstEqualizer : GLib.Object, IParams {
    
    private const int[] frequencies  = 
        { 50,     80,    120,   250,   500,   1000,  2000,   4500,   7600,   15000 };
    
    private const double[] bw_ranges = 
        { 100.0,  100.0, 100.0, 200.0, 300.0, 500.0, 2000.0, 3000.0, 3500.0, 5000.0 };
    
    private GLib.List<TenBandPreset> presets;
    public dynamic Gst.Element eq;
    
    public void read_params_data() {
        for(int i = 0; i < 10; ++i) {
            if(!Params.get_bool_value("not_use_eq"))
                this[i] = Params.get_double_value("eq_band%d".printf(i));
            else
                this[i] = 0.0;
        }
        if(!Params.get_bool_value("not_use_eq"))
            gst_player.preamplification = 
                (Params.get_double_value("preamp") == 0.0 ? 1.0 : Params.get_double_value("preamp"));
        else
            gst_player.preamplification = 1.0;
    }

    public void write_params_data() {
//        for(int i = 0; i < 10; ++i)
//            Params.set_double_value("eq_band%d".printf(i), this[i]);
    }

    public class TenBandPreset {
        
        public string name { get; set; default = ""; }
        public double pre_gain { get; set; }
        
        public double[] freq_band_gains;
        
        public TenBandPreset(string   name = "", 
                             double[] band_gains,
                             double pre_gain) {
            this.name = name;
            this.pre_gain = pre_gain;
            this.freq_band_gains = new double[10];
            for(int i = 0; i < 10; ++i)
                this.freq_band_gains[i] = band_gains[i];
            //print("created preset %s\n", name);
        }
        
        public double get(int index) {
            if(index < 0 || index > 9)
                return 0.0;
            return freq_band_gains[index];
        }
        
        public void set(int index, double val) {
            if(index < 0 || index > 9)
                return;
            freq_band_gains[index] = val;
        }
    }
    
    public bool available { get; set; }
    
    public GstEqualizer() {
        Params.iparams_register(this);
        available = make_gst_elements();
        make_default_presets();
    }
    
    public new double get(int idx) {
        double gain = 0.0;
        if(eq == null)
            return 0.0;
        GLib.Object bandgain =
            ((Gst.ChildProxy)eq).get_child_by_name("band%d".printf(idx));
        
        bandgain.get("gain", out gain);
        
        if(gain >= 0) { // map to the allowed range from -100% to 100% (-24 dB to 12 dB)
            gain /= 0.12;
        }
        else {
            gain /= 0.24;
        }
        return gain;
    }

    public new void set(int idx, double gain) {
        if(eq == null)
            return;
        GLib.Object bandgain =
            ((Gst.ChildProxy)eq).get_child_by_name("band%d".printf(idx));
        
        if(gain >= 0) { // map to the allowed rnge from -24 dB to 12 dB
            gain *= 0.12;
        }
        else {
            gain *= 0.24;
        }
        bandgain.set("gain", gain);
    }
    
    public void get_frequencies(out int[] freqs) {
        freqs = new int[10];
        for(int i = 0; i < 10; i++) {
            freqs[i] = frequencies[i];
        }
    }
    
    public int preset_count() {
        if(presets == null)
            return 0;
        return (int)presets.length();
    }
    public TenBandPreset? get_preset(int idx) {
        if(presets.length() == 0)
            return null;
        if(idx < 0)
            idx = 0;
        if(idx > presets.length() - 1)
            idx = (int)presets.length() - 1;
        TenBandPreset? pres = this.presets.nth_data(idx) as TenBandPreset;
        return pres;
    }
    
    private void make_default_presets() {
        presets = new GLib.List<TenBandPreset>();

        presets.prepend(
            new TenBandPreset(_("Dance"), 
                              { 20.0, 20.0, 12.0, 0.0, 0.0, -10.0, -20.0, 0.0, 10.0, 10.0 },
                              1.0
        ));
        presets.prepend(
            new TenBandPreset(_("Pop"), 
                              { -10.0, 10.0, 15.0, 28.0, 20.0, -5.0, -10.0, -10.0, 0.0, 0.0 },
                              1.0
        ));
        presets.prepend(
            new TenBandPreset(_("Techno"), 
                              { 30.0, 20.0, 0.0, -10.0, -5.0, 0.0, 25.0, 30.0, 30.0, 22.0 },
                              1.0
        ));
        presets.prepend(
            new TenBandPreset(_("Club"), 
                              { 0.0, 0.0, 10.0, 20.0, 20.0, 20.0, 10.0, 0.0, 0.0, 0.0 },
                              1.0
        ));
        presets.prepend(
            new TenBandPreset(_("Jazz"), 
                              { -5.0, 0.0, 0.0, 10.0, 30.0, 30.0, 15.0, 5.0, 5.0, 0.0 },
                              1.0
        ));
        presets.prepend(
            new TenBandPreset(_("Rock"), 
                              { 20.0, 5.0, -10.0, -20.0, -5.0, 5.0, 20.0, 35.0, 35.0, 40.0 },
                              1.1
        ));
        presets.prepend(
            new TenBandPreset(_("Maximum Treble"), 
                              { -30.0, -30.0, -20.0, -15.0, 0.0, 15.0, 50.0, 70.0, 70.0, 70.0 },
                              0.8
        ));
        presets.prepend(
            new TenBandPreset(_("Maximum Bass"), 
                              { 60.0, 60.0, 60.0, 10.0, 0.0, -25.0, -30.0, -30.0, -30.0, -30.0 },
                              0.9
        ));
        presets.prepend(
            new TenBandPreset(_("Classic"), 
                              { -5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -10.0, -10.0, -15.0 },
                              0.8
        ));
        // "Custom" always has to be in this position
        presets.prepend(
            new TenBandPreset(_("Custom"), 
                              { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                              1.0
        ));
        // "Default" always has to be in this position
        presets.prepend(
            new TenBandPreset(_("Default"), 
                              { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                              1.0
        ));
    }
    
    private bool make_gst_elements() {
        if(eq == null)
            eq = ElementFactory.make("equalizer-10bands", null);
        if(eq == null)
            return false;
        for(int i = 0; i < 10; i++) {
            double range = bw_ranges[i];
            double f = frequencies[i];
            GLib.Object? bandgain = ((Gst.ChildProxy)eq).get_child_by_name("band%d".printf(i));
//            Gst.Object? bandgain = ((Gst.ChildProxy)eq).get_child_by_name("band%d".printf(i));
            assert(bandgain != null);
            bandgain.set("freq", f,
                         "gain", 0.0,
                         "bandwidth", range
            );
        }
        return true;
    }
}


