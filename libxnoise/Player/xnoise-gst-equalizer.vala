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


public class Xnoise.GstEqualizer : GLib.Object, IParams {
    
    private const int[] frequencies  = 
        { 50,     200,   350,   500,   750,   1000,  3400,   5000,   10000,  15000 };
    
    private const double[] bw_ranges = 
        { 120.0,  150.0, 150.0, 250.0, 300.0, 500.0, 2000.0, 3000.0, 3500.0, 5000.0 };
    
    private GLib.List<TenBandPreset> presets;
    public dynamic Gst.Element eq;
    
    public void read_params_data() {
        //TODO
    }

    public void write_params_data() {
        //TODO
    }

    public class TenBandPreset {
        
        public string name { get; set; default = ""; }
        public double[] freq_band_gains;
        
        public TenBandPreset(string   name = "", 
                             double[] band_gains) {
            this.name = name;
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
    
    
    public GstEqualizer() {
        Params.iparams_register(this);
        make_gst_elements();
        make_default_presets();
    }
    
    public new double get(int idx) {
        double gain = 0.0;
        Gst.Object bandgain =
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
        Gst.Object bandgain =
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
            new TenBandPreset("Dance", 
                              { 50.0, 35.0, 10.0, 0.0, 0.0, -30.0, -40.0, -40.0, 0.0, 0.0 }
        ));
        presets.prepend(
            new TenBandPreset("Pop", 
                              { -10.0, 25.0, 35.0, 40.0, 25.0, -5.0, -15.0, -15.0, -10.0, -10.0 }
        ));
        presets.prepend(
            new TenBandPreset("Club", 
                              { 0.0, 0.0, 20.0, 30.0, 30.0, 30.0, 20.0, 0.0, 0.0, 0.0 }
        ));
        presets.prepend(
            new TenBandPreset("Jazz", 
                              { -10.0, 0.0, 0.0, 10.0, 30.0, 40.0, 40.0, 10.0, 0.0, 0.0 }
        ));
        presets.prepend(
            new TenBandPreset("Rock", 
                              { 40.0, 25.0, -30.0, -40.0, -20.0, 20.0, 45.0, 55.0, 55.0, 55.0 }
        ));
        presets.prepend(
            new TenBandPreset("Techno", 
                              { 40.0, 30.0, 0.0, -30.0, -25.0, 0.0, 40.0, 50.0, 50.0, 45.0 }
        ));
        presets.prepend(
            new TenBandPreset("Full Treble", 
                              { -50.0, -50.0, -50.0, -25.0, 15.0, 55.0, 80.0, 80.0, 80.0, 80.0 }
        ));
        presets.prepend(
            new TenBandPreset("Full Bass", 
                              { 70.0, 70.0, 70.0, 40.0, 20.0, -45.0, -50.0, -55.0, -55.0, -55.0 }
        ));
        presets.prepend(
            new TenBandPreset("Classic", 
                              { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -40.0, -40.0, -40.0, -50.0 }
        ));
        presets.prepend(
            new TenBandPreset("Default", 
                              { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
        ));
    }
    
    private void make_gst_elements() {
        if(eq == null)
            eq = ElementFactory.make("equalizer-10bands", null);
        
        double last = 0.0;
        for(int i = 0; i < 10; i++) {
            double range = bw_ranges[i];
            double f = frequencies[i];
            Gst.Object? bandgain = ((Gst.ChildProxy)eq).get_child_by_name("band%d".printf(i));
            assert(bandgain != null);
            bandgain.set(
               "freq", f,
               "gain", 0.0,
               "bandwidth", range
            );
            last = frequencies[i];
        }
    }
}


