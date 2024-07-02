

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.common.all;

entity top is
	port (
		clk_brd_50_i 		: in 	std_logic;
		btn1_i				: in 	std_logic;

		mx_cs_o				: out	std_logic;
		mx_ck_o				: out	std_logic;
		mx_d_o				: out	std_logic
		);
end top;

architecture rtl of top is

	constant CLOCKSPEED : natural := 6250000;
	
	type t_matrix is array(0 to 16*8-1) of std_logic_vector(7 downto 0);

	constant c_test_data : t_matrix := (

		-- 0
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"10010000",
		"10010000",
		"01100000",
		--1
		"00000000",
		"00000000",
		"00000000",
		"00100000",
		"01100000",
		"00100000",
		"00100000",
		"01110000",
		--2
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"00100000",
		"01000000",
		"11110000",
		--3
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"00100000",
		"10010000",
		"01100000",
		--4
		"00000000",
		"00000000",
		"00000000",
		"10010000",
		"10010000",
		"01110000",
		"00010000",
		"00010000",
		--5
		"00000000",
		"00000000",
		"00000000",
		"11110000",
		"10000000",
		"11100000",
		"00010000",
		"11100000",
		--6
		"00000000",
		"00000000",
		"00000000",
		"00110000",
		"01000000",
		"11100000",
		"10010000",
		"01100000",
		--7
		"00000000",
		"00000000",
		"00000000",
		"11110000",
		"10010000",
		"00100000",
		"01000000",
		"10000000",
		--
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"01100000",
		"10010000",
		"01100000",
		--9
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"01110000",
		"00010000",
		"01100000",
		--a
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"00010000",
		"01110000",
		"10010000",
		"01101000",
		--b
		"00000000",
		"00000000",
		"00000000",
		"10000000",
		"10000000",
		"11100000",
		"10010000",
		"11100000",
		--c
		"00000000",
		"00000000",
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10000000",
		"01100000",
		--d
		"00000000",
		"00000000",
		"00000000",
		"00010000",
		"00010000",
		"01110000",
		"10010000",
		"01110000",
		--e
		"00000000",
		"00000000",
		"00000000",
		"01100000",
		"10010000",
		"11100000",
		"10000000",
		"01110000",
		--f
		"00000000",
		"00000000",
		"00000000",
		"00110000",
		"01000000",
		"11100000",
		"01000000",
		"01000000"


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

	-- pll
	signal i_pll_lock		: std_logic;

	signal test_count		: unsigned(15 downto 0);

	constant WT : natural := CLOCKSPEED / 30;

	signal r_wait_ctr		: unsigned(numbits(WT) downto 0);

	signal i_char_ix : std_logic_vector(3 downto 0);
	signal i_char_a  : std_logic_vector(6 downto 0);

begin

	pchar:process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			r_wait_ctr <= to_unsigned(WT-1, r_wait_ctr'length);
			test_count <= (others => '0');
			i_scan_tgl <= '1';
		elsif rising_edge(i_clk) then
			if r_wait_ctr(r_wait_ctr'high) = '1' then
				r_wait_ctr <= to_unsigned(WT-1, r_wait_ctr'length);
				test_count <= test_count + 1;
				i_scan_tgl <= not i_scan_ack;
			else
				r_wait_ctr <= r_wait_ctr - 1;
			end if;
		end if;
	end process;

	i_char_ix <= 	std_logic_vector(
				test_count(15 downto 12) when i_dispdata_A(4 downto 3) = "00" else
				test_count(11 downto 8)  when i_dispdata_A(4 downto 3) = "01" else
				test_count(7 downto 4)   when i_dispdata_A(4 downto 3) = "10" else
				test_count(3 downto 0)
				);


	i_char_a <= i_char_ix & i_dispdata_A(2 downto 0);


	i_dispdata_D <= c_test_data(
		to_integer(unsigned(i_char_a))
		);

	mx_cs_o <= i_mx_cs;
	mx_ck_o <= i_mx_clk;
	mx_d_o  <= i_mx_d;

	e_pll:entity work.Gowin_PLL
    port map (
        clkout0 => i_clk,
        clkin => clk_brd_50_i,
        lock => i_pll_lock
    );

	i_rst <= '1' when i_pll_lock = '0' else
			 '1' when btn1_i = '1' else
			 '0';

	i_clken <= '1';

	e_dut:entity work.matrix8x8
	generic map (
		G_PANELS => 4
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

	

end rtl;