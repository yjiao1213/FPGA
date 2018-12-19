----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2018/10/01 10:54:40
-- Design Name: 
-- Module Name: seven_seg - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seven_seg is
    Port (clk: in std_logic;
          sw: in std_logic_vector(15 downto 0);
          seg: out std_logic_vector(6 downto 0);
          num_seg: out std_logic_vector(7 downto 0));
end seven_seg;

architecture Behavioral of seven_seg is
function swtoseg(x:std_logic_vector) return std_logic_vector is
variable y:std_logic_vector(6 downto 0);
begin
    if x = "0000" then y := NOT "0111111";
    elsif x = "0001" then y := NOT "0000110";
    elsif x = "0010" then y := NOT "1011011";
    elsif x = "0011" then y := NOT "1001111";
    elsif x = "0100" then y := NOT "1100110";
    elsif x = "0101" then y := NOT "1101101";
    elsif x = "0110" then y := NOT "1111101";
    elsif x = "0111" then y := NOT "0000111";
    elsif x = "1000" then y := NOT "1111111";
    elsif x = "1001" then y := NOT "1101111";
    elsif x = "1010" then y := NOT "1110111";
    elsif x = "1011" then y := NOT "1111100";
    elsif x = "1100" then y := NOT "0111001";
    elsif x = "1101" then y := NOT "1011110";
    elsif x = "1110" then y := NOT "1111001";
    else y := NOT "1110001";
    end if;
    return y;
end swtoseg;

SIGNAL count:integer range 0 to 5000;
SIGNAL index_seg: integer range 0 to 3;
SIGNAL counter:integer range 0 to 3;
SIGNAl seg0:std_logic_vector(6 downto 0);
SIGNAl seg1:std_logic_vector(6 downto 0) := NOT "0111111";
SIGNAl seg2:std_logic_vector(6 downto 0) := NOT "0111111";
SIGNAl seg3:std_logic_vector(6 downto 0) := NOT "0111111";
SIGNAL sw0: std_logic_vector(3 downto 0);
SIGNAL sw1: std_logic_vector(3 downto 0);
SIGNAL sw2: std_logic_vector(3 downto 0);
SIGNAL sw3: std_logic_vector(3 downto 0);

begin
process(clk)
begin
if clk'event and clk = '1'THEN 
    if count = 5000 then
        count <= 0;
        if index_seg = 3 then
            index_seg <= 0;
        else
            index_seg <= index_seg + 1;
        end if;
    else
        count <= count + 1;
    end if;
end if;
end process;

process(index_seg)
begin
if index_seg = 0 then
    num_seg<="01111111";
    seg <= seg0;
elsif index_seg = 1 then
    num_seg<="10111111";
    seg <= seg1;
elsif index_seg = 2 then
    num_seg<="11011111";
    seg <= seg2;
else
    num_seg<="11101111";
    seg <= seg3;
end if;

end process;

process(clk,sw)
begin
    sw0(3 downto 0) <= sw(3 downto 0);
    sw1(3 downto 0) <= sw(7 downto 4);
    sw2(3 downto 0) <= sw(11 downto 8);
    sw3(3 downto 0) <= sw(15 downto 12);
    
    
    seg0 <= swtoseg(sw0);
    seg1 <= swtoseg(sw1);
    seg2 <= swtoseg(sw2);
    seg3 <= swtoseg(sw3);
end process;


end Behavioral;
