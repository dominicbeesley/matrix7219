--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.9.02
--Part Number: GW5A-LV25MG121NC2/I1
--Device: GW5A-25
--Device Version: A
--Created Time: Tue Jul  2 12:56:07 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_PLL
    port (
        lock: out std_logic;
        clkout0: out std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Gowin_PLL
    port map (
        lock => lock_o,
        clkout0 => clkout0_o,
        clkin => clkin_i
    );

----------Copy end-------------------
