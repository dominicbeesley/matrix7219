library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.common.all;

entity matrix8x8 is
	generic (
		G_PANELS : positive := 1
	);
	port(

		rst_i			: in	std_logic;
		clk_i			: in	std_logic;		
		clken_i			: in	std_logic;			-- clk/clken should be <20MHz and each column will be 
													-- clocked out on each second clken

		-- command interface
		scan_tgl_i		: in	std_logic;			-- flip this to intiate scan
		scan_ack_o		: out	std_logic;			-- flip to match scan_tgl_i when scan started

		-- data memory interface
		A_o				: out	std_logic_vector(numbits(G_PANELS*8)-1 downto 0);
		D_i				: in	std_logic_vector(7 downto 0);

		-- 7219 interface
		clk_o			: out	std_logic;			-- serial clock
		cs_o			: out	std_logic;			-- load/sel
		d_o				: out	std_logic 			-- serial data out
	);
end matrix8x8;

architecture rtl of matrix8x8 is

	type t_state is (reset, init_dec, init_int, init_scn, init_shu, init_fin, idle, scan_start, scan);
	signal r_state : t_state;

	signal r_out_sr	: std_logic_vector(15 downto 0);
	signal r_out_cs	: std_logic_vector(16*G_PANELS downto 0);

	signal r_scan_ack	: std_logic;
	signal r_scan_req	: std_logic;

	signal r_scan_ix	: unsigned(3 downto 0);	

	signal r_scan_pnl	: unsigned(numbits(G_PANELS) downto 0); -- 1 extra bit for wrap round

	signal r_ck_out		: std_logic;
	signal r_ring_ld	: std_logic_vector(15 downto 0) := (0 => '1', others => '0');

begin
	
	clk_o <= r_ck_out;

	G_PNL1:if G_PANELS = 1 generate
		A_o <= std_logic_vector(r_scan_ix(2 downto 0));
	end generate;
	G_PNLX:if G_PANELS > 1 generate
		A_o <= std_logic_vector(r_scan_pnl(r_scan_pnl'high-1 downto 0) & r_scan_ix(2 downto 0));
	end generate;
	scan_ack_o <= r_scan_ack;

	p_state:process(rst_i, scan_tgl_i, clk_i)
	begin
		if rst_i = '1' then
			r_state <= reset;
			r_out_cs <= (others => '1');
			r_out_sr <= (others => '0');
			r_scan_ack <= '0';
			r_scan_req <= '0';
			r_ck_out <= '0';
			r_scan_ix <= (others=> '0');
			r_scan_pnl <= (others => '0');
			r_ring_ld  <= (0 => '1', others => '0');
		elsif rising_edge(clk_i) then
		 	if clken_i = '1' then
				if r_ck_out = '0' then
					-- falling edge of ck_out
					case r_state is
						when reset =>
							r_out_cs <= (others => '0');
							r_out_sr <= x"0900";			-- decode mode
							r_state <= init_dec;
						when init_dec =>
							if r_out_cs(r_out_cs'high) = '1' then
								r_out_cs <= (others => '0');
								r_out_sr <= x"0A01";		-- intensity mode
								r_state <= init_int;
							end if;
						when init_int =>
							if r_out_cs(r_out_cs'high) = '1' then
								r_out_cs <= (others => '0');
								r_out_sr <= x"0B07";		-- scan limit
								r_state <= init_scn;
							end if;
						when init_scn =>
							if r_out_cs(r_out_cs'high) = '1' then
								r_out_cs <= (others => '0');
								r_out_sr <= x"0C01";		-- leave shutdown
								r_state <= init_fin;
							end if;
						when init_fin =>
							if r_out_cs(r_out_cs'high) = '1' then
								r_state <= idle;
							end if;
						when idle =>
							if scan_tgl_i /= r_scan_ack then
								r_scan_ix <= (others => '0');
								r_scan_pnl <= (others => '0');
								r_scan_req <= scan_tgl_i;
								r_state <= scan_start;
							end if;
						when scan_start =>
							r_out_cs <= (others => '0');
							r_out_sr <= "0000" & std_logic_vector(r_scan_ix+1) & D_i;
							r_state <= scan;
							r_ring_ld  <= (0 => '1', others => '0');
							if G_PANELS > 1 then
								r_scan_pnl <= r_scan_pnl + 1;
							end if;
						when scan =>
							if r_out_cs(r_out_cs'high) = '1' then 
								if r_scan_ix + 1 = to_unsigned(8, r_scan_ix'length) then
									r_state <= idle;
									r_scan_ack <= r_scan_req;
									r_out_sr <= (others => '0');
								else
									r_scan_ix <= r_scan_ix + 1;
									r_state <= scan_start;
									r_scan_pnl <= (others => '0');
								end if;
							elsif r_ring_ld(0) = '1' then
								r_out_sr <= "0000" & std_logic_vector(r_scan_ix+1) & D_i;
								if G_PANELS > 1 then
									r_scan_pnl <= r_scan_pnl + 1;
								end if;
							end if;
						when others =>
							r_state <= reset;
					end case;
					r_ck_out <= '1';
				else
					-- falling edge clock out
					r_ck_out <= '0';
					d_o <= r_out_sr(r_out_sr'high);
					cs_o <= r_out_cs(r_out_cs'high-1);
					r_out_cs <= r_out_cs(r_out_cs'high-1 downto 0) & '1';
					r_out_sr <= r_out_sr(r_out_sr'high-1 downto 0) & r_out_sr(r_out_sr'high);
					r_ring_ld <= r_ring_ld(0) & r_ring_ld(r_ring_ld'high downto 1);
				end if;
			end if;
		end if;
	end process;




end rtl;
