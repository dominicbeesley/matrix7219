

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
	
	type t_chardef is array(0 to 15, 0 to 4) of std_logic_vector(4 downto 0);

	constant c_test_data : t_chardef := (

		-- 0
		(
			"01100",
			"10010",
			"10010",
			"10010",
			"01100"
		),
		--1
		(
			"00100",
			"01100",
			"00100",
			"00100",
			"01110"
		),
		--2
		(
			"01100",
			"10010",
			"00100",
			"01000",
			"11110"
		),
		--3
		(
			"01100",
			"10010",
			"00100",
			"10010",
			"01100"
		),
		--4
		(
			"10010",
			"10010",
			"01110",
			"00010",
			"00010"
		),
		--5
		(
			"11110",
			"10000",
			"11100",
			"00010",
			"11100"
		),
		--6
		(
			"00110",
			"01000",
			"11100",
			"10010",
			"01100"
		),
		--7
		(
			"11110",
			"10010",
			"00100",
			"01000",
			"10000"
		),
		--8
		(
			"01100",
			"10010",
			"01100",
			"10010",
			"01100"
		),
		--9
		(
			"01100",
			"10010",
			"01110",
			"00010",
			"01100")
		,
		--a
		(
			"01100",
			"00010",
			"01110",
			"10010",
			"01101"
		),
		--b
		(
			"10000",
			"10000",
			"11100",
			"10010",
			"11100"
		),
		--c
		(
			"00000",
			"00000",
			"01100",
			"10000",
			"01100"
		),
		--d
		(		
			"00010",
			"00010",
			"01110",
			"10010",
			"01110"
		),
		--e
		(
			"01100",
			"10010",
			"11100",
			"10000",
			"01110"
		),
		--f
		(
			"00110",
			"01000",
			"11100",
			"01000",
			"01000"
		)
		);

	type t_disp_ram is array(0 to 31) of std_logic_vector(7 downto 0);

	signal r_disp_ram		: t_disp_ram;

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

	signal r_test_count		: unsigned(15 downto 0);
	signal r_clken_test_up	: std_logic;

	constant WT : natural := CLOCKSPEED / 30;

	signal r_wait_ctr		: unsigned(numbits(WT) downto 0);

	signal i_char_ix : std_logic_vector(3 downto 0);
	signal i_char_a  : std_logic_vector(6 downto 0);



begin

	p_ram_update:process(i_rst, i_clk)
	variable vr_data : std_logic_vector(23 downto 0);

	type t_up_state is (idle, up);
	variable vr_state : t_up_state;
	variable p : std_logic_vector(4 downto 0);
	variable col : integer;
	begin
		
		if i_rst = '1' then
			i_scan_tgl <= '1';
			vr_state := idle;
		elsif rising_edge(i_clk) then
			
			if r_clken_test_up = '1' then
				vr_data := not std_logic_vector(r_test_count(8 downto 1)) & std_logic_vector(r_test_count);
				vr_state := up;
			end if;

			case vr_state is
				when idle =>
					null;
				when up =>
					
					for I in 0 to 5 loop -- digit
						for j in 0 to 4 loop -- row
							p := c_test_data(to_integer(unsigned(vr_data(3+4*I downto 4*I))), J);
							for k in 0 to 4 loop -- bit
								col := I*5 + K;
								r_disp_ram((3- (col / 8)) * 8 + J)(col mod 8) <= p(k);
							end loop;
						end loop;
					end loop;

					i_scan_tgl <= not i_scan_ack;
			end case;
			
		end if;

	end process;


	pchar:process(i_rst, i_clk)
	begin
		if i_rst = '1' then
			r_wait_ctr <= to_unsigned(WT-1, r_wait_ctr'length);
			r_test_count <= (others => '0');
			r_clken_test_up <= '0';
		elsif rising_edge(i_clk) then
			r_clken_test_up <= '0';
			if r_wait_ctr(r_wait_ctr'high) = '1' then
				r_wait_ctr <= to_unsigned(WT-1, r_wait_ctr'length);
				r_test_count <= r_test_count + 1;
				r_clken_test_up <= '1';
			else
				r_wait_ctr <= r_wait_ctr - 1;
			end if;
		end if;
	end process;

	i_dispdata_D <= r_disp_ram(
		to_integer(unsigned(i_dispdata_A))
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