library vunit_lib;
context vunit_lib.vunit_context;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use std.textio.all;


entity x4_8x8_tb is
	generic (
		runner_cfg : string
		);
end x4_8x8_tb;

architecture rtl of x4_8x8_tb is

	constant G_PANELS : positive := 4;

	constant CLOCKSPEED : natural := 1000000;
	constant CLOCKPER : time := 500000 us / CLOCKSPEED;
	

	type t_matrix is array(0 to 31) of std_logic_vector(7 downto 0);

	constant c_test_data : t_matrix := (
		"10101010",
		"01010101",
		"11001100",
		"00110011",
		"10100101",
		"01011010",
		"11110000",
		"00001111",

		"00110110",
		"01111111",
		"01111111",
		"00111110",
		"00111110",
		"00011100",
		"00011100",
		"00001000",

		"10000001",
		"01000010",
		"00100100",
		"00011000",
		"00011000",
		"00100100",
		"01000010",
		"10000001",

		"01010101",
		"01010101",
		"01010101",
		"01010101",
		"01010101",
		"01010101",
		"01010101",
		"01010101"

		);

	signal i_rst			: std_logic;
	signal i_clk			: std_logic;		
	signal i_clken			: std_logic;			-- clk/clken should be <20MHz and each column will be 
												-- clocked out on each second clken

	-- command interface
	signal i_scan_tgl		: std_logic;			-- flip this to intiate scan
	signal i_scan_ack		: std_logic;			-- flip to match scan_tgl_i when scan started

	-- data memory interface
	signal i_dispdata_A		: std_logic_vector(4 downto 0);
	signal i_dispdata_D		: std_logic_vector(7 downto 0);

	-- 7219 interface
	signal i_mx_clk			: std_logic;			-- serial clock
	signal i_mx_cs			: std_logic;			-- load/sel
	signal i_mx_d			: std_logic; 			-- serial data out

begin


	p_clk:process
	begin
		i_clk <= '1';
		wait for CLOCKPER;
		i_clk <= '0';
		wait for CLOCKPER;
	end process;		

	i_dispdata_D <= c_test_data(to_integer(unsigned(i_dispdata_A)));

	p_main:process
	begin

		test_runner_setup(runner, runner_cfg);

		while test_suite loop

			if run("pattern") then
				i_clken <= '1';
				i_rst <= '1';
				i_scan_tgl <= '1';
				wait for 2 us;
				i_rst <= '0';
				
				wait until i_scan_ack = i_scan_tgl;
				wait for 400 us;


			end if;

		end loop;

		test_runner_cleanup(runner); -- Simulation ends here
	end process;

	e_dut:entity work.matrix8x8
	generic map (
		G_PANELS => G_PANELS
	)
	port map( 
		rst_i => i_rst,
		clk_i => i_clk,
		clken_i => i_clken,

		scan_tgl_i => i_scan_tgl,
		scan_ack_o => i_scan_ack,

		A_o => i_dispdata_A,
		D_i => i_dispdata_D,

		clk_o => i_mx_clk,
		cs_o => i_mx_cs,
		d_o => i_mx_d
    );

	
	p_monitor_ser:process(i_mx_cs, i_mx_clk)
	variable sr : std_logic_vector(16*G_PANELS-1 downto 0) := (others => 'X');
	begin

		if rising_edge(i_mx_cs) then
			report "SHIFT: " & to_string(sr) & " (" & to_hstring(sr) & ")." severity note;
			sr := (others =>'X');
		end if;

		if rising_edge(i_mx_clk) then
			sr := sr(sr'high-1 downto 0) & i_mx_d;
		end if;
		
	end process;


end rtl;