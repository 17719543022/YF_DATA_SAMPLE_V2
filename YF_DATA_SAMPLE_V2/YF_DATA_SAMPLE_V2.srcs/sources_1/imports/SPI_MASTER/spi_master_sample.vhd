library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity spi_master_sample is
generic(
	DW_DIN:INTEGER:=16;
	SPI_DIV:INTEGER:=16;			---最小分频比为2
	T_WAITE:INTEGER:=30;
	DEV_NUM:INTEGER:=2
);
port(
	clkin			:in std_logic;
	rst_n			:in std_logic;
------------------------------
	s_axis_tvalid	:in std_logic;
	s_axis_tready	:out std_logic;
	s_axis_tdata 	:in std_logic_vector(DEV_NUM*DW_DIN-1 downto 0);
------------------------------
	spi_cs			:out std_logic;
	spi_clk			:out std_logic;
	spi_sdo			:out std_logic_vector(DEV_NUM-1 downto 0)	
);
end spi_master_sample;
architecture behav of spi_master_sample is

constant spi_div_half:integer:=SPI_DIV/2;
signal cnt_spi_clk:integer:=0;

signal sclk    :std_logic:='0';
signal tx_en   :std_logic:='0';
signal spi_working   :std_logic:='0';
signal cs   :std_logic:='1';
signal s_axis_tready_buf   :std_logic:='0';
signal sdo_buf :std_logic_vector(DEV_NUM-1 downto 0);

type t1 is array(0 to DEV_NUM-1 ) of std_logic_vector(DW_DIN-1 downto 0);
signal tx_data:t1;

signal s1 :integer range 0 to 3:=0;





begin



s_axis_tready<=s_axis_tready_buf;



-- process(clkin)
-- begin
	-- if rising_edge(clkin) then
		-- if rst_n='0' then
			-- cnt_spi_clk<=spi_div-1;
			-- sclk<='0';
		-- else
			-- if spi_working='1' then
				-- if cnt_spi_clk>=SPI_DIV-1 then
					-- cnt_spi_clk<=0;
				-- else
					-- cnt_spi_clk<=cnt_spi_clk+1;
				-- end if;
				
				-- if cnt_spi_clk=0 then
					-- sclk<='0';
				-- elsif cnt_spi_clk=spi_div_half then
					-- sclk<='1';
				-- else
					-- sclk<=sclk;
				-- end if;
				
				-- if cnt_spi_clk=spi_div-1 then
					-- tx_en<='1';
				-- else
					-- tx_en<='0';
				-- end if;
			-- else
				-- cnt_spi_clk<=spi_div-1;
				-- sclk<='0';
			-- end if;
		-- end if;
	-- end if;
-- end process;

spi_clk<=sclk;
spi_cs<=cs;
spi_sdo<=sdo_buf;

process(clkin)
variable cnt:integer:=0;
begin
	if rising_edge(clkin) then
		if rst_n='0' then
			s1<=0;
			cnt:=0;
            cs<='1';
            cnt_spi_clk <= 0;
		else
			case s1 is
				when 0=>
					if s_axis_tvalid='1'  and s_axis_tready_buf='1' then
						for i in 0 to DEV_NUM-1 loop
							tx_data(i)<=s_axis_tdata((i+1)*DW_DIN-1 downto i*DW_DIN);
						end loop;
						s1<=1;
						s_axis_tready_buf<='0';
					else
						s_axis_tready_buf<='1';
						s1<=s1;
					end if;
					cs<='1';
					spi_working<='0';
					cnt:=0;
                    cnt_spi_clk <= 0;
				
				
				when 1=>
					cs<='0';
					if cnt_spi_clk = 0 then
						for i in 0 to DEV_NUM-1 loop
							sdo_buf(i)<=tx_data(i)(DW_DIN-1-cnt);
						end loop;
						if cnt=DW_DIN-1 then
							s1<=2;
							cnt:=0;
						else
							cnt:=cnt+1;
							s1<=s1;
						end if;
					else
						cnt:=cnt;
					end if;
                    
                    if cnt_spi_clk=0 then
                        sclk<='0';
                    elsif cnt_spi_clk=spi_div_half then
                        sclk<='1';
                    else
                        sclk<=sclk;
                    end if;  
                    
                    if cnt_spi_clk>=SPI_DIV-1 then
                        cnt_spi_clk<=0;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;                    
				
				when 2=>
					if cnt_spi_clk = 0 then
						cs<='1';
						s1<=3;
						spi_working<='0';
					else
						s1<=s1;
					end if;
                    
                    
                    if cnt_spi_clk=0 then
                        sclk<='0';
                    elsif cnt_spi_clk=spi_div_half then
                        sclk<='1';
                    else
                        sclk<=sclk;
                    end if;  
                    
                    if cnt_spi_clk>=SPI_DIV-1 then
                        cnt_spi_clk<=0;
                    else
                        cnt_spi_clk<=cnt_spi_clk+1;
                    end if;  
				
				when 3=>
					if cnt=T_WAITE-1 then
						cnt:=0;
						s1<=0;
					else
						cnt:=cnt+1;
					end if;

				when others=>
					s1<=0;
			end case;
		end if;
	end if;
end process;
					
					
						
						



end behav;