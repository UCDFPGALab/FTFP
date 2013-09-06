library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library IEEE_proposed;
use IEEE_proposed.float_pkg.all;

package simple_algs_package is

	function valid_eta(eta, eta_max : integer)
		return boolean;
		
	function calib_pf_jet(et : float (float_exponent_width downto -float_fraction_width);
								 reta : unsigned (15 downto 0))
		return float (float_exponent_width downto -float_fraction_width);

	constant
	
--	double CALIB_PF_JET[6*11] = {
--    1.114000,  2.297000, 5.959000, 1.181000,  0.728600,  0.367300, // eta = 0
--    0.784200,  4.331000, 2.672000, 0.574300,  0.881100,  0.408500, // eta = 1
--    0.961000,  2.941000, 2.400000, 1.248000,  0.666000,  0.104100, 
--    0.631800,  6.600000, 3.210000, 0.855100,  0.978600,  0.291000, 
--    0.345600,  8.992000, 3.165000, 0.579800,  2.146000,  0.491200, 
--    0.850100,  3.892000, 2.466000, 1.236000,  0.832300,  0.180900, 
--    0.902700,  2.581000, 1.453000, 1.029000,  0.676700, -0.147600, 
--    1.117000,  2.382000, 1.769000, 0.000000, -1.306000, -0.474100, 
--    1.634000, -1.010000, 0.718400, 1.639000,  0.672700, -0.212900, 
--    0.986200,  3.138000, 4.672000, 2.362000,  1.550000, -0.715400, 
--    1.245000,  1.103000, 1.919000, 0.305400,  5.745000,  0.862200, // Eta = 10
--  };

end simple_algs_package;
--
package body simple_algs_package is

	function valid_eta(eta, eta_max : integer)
		return boolean is
	begin
		if eta < 0 then
			return false;
		end if;
		if eta >= eta_max then
			return false;
		end if;
		return true;
	end valid_eta;
	
	function calib_pf_jet(et : float (float_exponent_width downto -float_fraction_width);
		  						 reta : unsigned (15 downto 0))
		return float (float_exponent_width downto -float_fraction_width) is
		variable abseta : integer := 10 - reta;
	begin
    
		if (reta < 11) then
			abseta := 10 - reta;
		end if;
    
    const double * p = &CALIB_PF_JET[6*abseta];
	 
    double cet = et * (p[0]+p[1]/(pow(log10(et),2)+p[2])+p[3]*exp(-p[4]*(log10(et)-p[5])*(log10(et)-p[5])));
    int tet = 4 * ((int) (cet / 4.0));
    if (tet > 252) tet = 252;
    return tet;
		
	end calib_pf_jet;
	

void simple_jets(JetRegionGrid & grid, std::vector<PhysicsObj> * jets){
   enum {NUM_PHI = JetRegionGrid::NUM_PHI};
   enum {NUM_ETA = JetRegionGrid::NUM_ETA};
   
   double etscale = 0.5;
   double seed = 10;
   unsigned mask = 0x7ff; // actually, this is only for HB/HE not HF... FIXME?
   
   // local maximums:
   //      (+1 eta)
   // NW(>=) N(>=) NE(>=)
   //  W(>)         E(>=) (+1 phi)
   // SW(> ) S(> ) SE(> )
   
   PhysicsObj jet;
   
   for (int rphi=0; rphi<NUM_PHI; rphi++){
      for (int reta=0; reta<NUM_ETA; reta++){
         unsigned nw, n, ne, w, c, e, sw, s, se;
         nw = n = ne = w = e = sw = s = se = 0;
         c = mask & grid.udata(reta,rphi);
         if (c < seed) continue;         
         e = mask & grid.udata(reta,rphi+1);	  	  
         w = mask & grid.udata(reta,rphi-1);	  	  
         if (valid_eta(reta+1,NUM_ETA)){
            n  = mask & grid.udata(reta+1,rphi);	  	  
            ne = mask & grid.udata(reta+1,rphi+1);	  	  
            nw = mask & grid.udata(reta+1,rphi-1);	  	  
         }
         if (valid_eta(reta-1,NUM_ETA)){
            s  = mask & grid.udata(reta-1,rphi);	  
            se = mask & grid.udata(reta-1,rphi+1);	  
            sw = mask & grid.udata(reta-1,rphi-1);	  
         }
         
         int lmax = 0;
         lmax = ((c >= nw) && (c >=  n) && (c >=  ne) && 
                 (c >  w)               && (c >=  e)  && 
                 (c >  sw) && (c >   s) && (c >   se));
         
         if (lmax) {
            double et = etscale * (nw + n + ne + w + c + e + sw + s + se);
            int corr_et = (int) calib_pf_jet(et, reta); //&GCT_JET_ETCALIB[6*abseta]);
            
            double phi = physical_phi(rphi, NUM_PHI);	    
            double eta = physical_eta_from_region_eta(reta);
            jet.pt  = corr_et;
            jet.eta = eta;
            jet.phi = phi;
            jet.quality = 0;
            jets->push_back(jet);
         }
      }
   } 

end simple_algs_package;
