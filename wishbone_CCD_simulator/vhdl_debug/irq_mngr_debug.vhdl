-------------------------------------------------------------------------------
--
--  File          :  irq_mnrg.vhd
--  Related files :  (none)
--
--  Author(s)     :  Fabrice Mousset (fabrice.mousset@laposte.net)
--  Project       :  Wishbone Interruption Manager
--
--  Creation Date :  2007/01/05
--
--  Description   :  This is the top file of the IP
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.numeric_std.all;
use work.common_decs.all;

entity irq_mngr is
  generic
    (
      id        : device_id := x"1009";
      irq_level : std_logic := '1'
      );
  port
    (
      -- Component external signals
      sysc    : in  syscon;
      irq     : out std_logic;          -- IRQ request
      -- Wishbone interface signals
      wbw     : in  wbws;
      wbr     : out wbrs;
      -- irq from other IP
      irqport : in  write_chan
      );
end entity;

-- ----------------------------------------------------------------------------
architecture RTL of irq_mngr is
-- ----------------------------------------------------------------------------

  signal irq_r, irq_old, irq_pend, irq_ack, irq_mask : write_chan;
  signal readdata                                    : read_chan;
  signal rd_ack                                      : std_logic;
  signal wr_ack                                      : std_logic;
begin

--  External signals synchronization process
  process(sysc.clk, sysc.reset)
  begin
    if(sysc.reset = '1') then
      irq_r   <= (others => '0');
      irq_old <= (others => '0');
    elsif(rising_edge(sysc.clk)) then
      irq_r   <= irqport;
      irq_old <= irq_r;
    end if;
  end process;


--  Interruption requests latching process on rising edge
  process(sysc.clk, sysc.reset)
  begin
    if(sysc.reset = '1') then
      irq_pend <= (others => '0');
    elsif(rising_edge(sysc.clk)) then
      irq_pend <= (not irq_ack) and (irq_pend or (irq_r and (not irq_old) and irq_mask));
    end if;
  end process;


--  Register reading process
  process(sysc.clk, sysc.reset)
  begin
    if(sysc.reset = '1') then
      rd_ack   <= '0';
      readdata <= (others => '0');
    elsif(rising_edge(sysc.clk)) then
      rd_ack <= '0';
      if check_wb0(wbw) then
        rd_ack <= '1';
        if(wbw.c.address(1 downto 0) = "00") then
          --readdata <= irq_mask;
          readdata <= x"F00F";
        elsif(wbw.c.address(1 downto 0) = "01") then
          readdata <= x"D0D0";
        elsif(wbw.c.address(1 downto 0) = "11") then
          readdata <= id;
        else
          readdata <= x"BAD0";
        end if;
      end if;
    end if;
  end process;

--  Register update process
  process(sysc.clk, sysc.reset)
  begin
    if(sysc.reset = '1') then
      irq_ack  <= (others => '0');
      wr_ack   <= '0';
      irq_mask <= (others => '0');
    elsif(rising_edge(sysc.clk)) then
      irq_ack <= (others => '0');
      wr_ack  <= '0';
      if check_wb1(wbw) then
        wr_ack <= '1';
        if(wbw.c.address(1 downto 0) = "00") then
          irq_mask <= wbw.c.writedata;
        elsif(wbw.c.address(1 downto 0) = "01") then
          irq_ack <= wbw.c.writedata;
        end if;
      end if;
    end if;
  end process;

  irq <= irq_level when(conv_integer(irq_pend) /= 0 and sysc.reset = '0')
         else not irq_level;
  wbr.ack      <= rd_ack or wr_ack;
  wbr.readdata <= readdata when check_wb0(wbw)
                  else (others => '0');

end architecture RTL;
