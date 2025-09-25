library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ctrl_74hc595 is
generic(
    device_num:integer:=3;      --级联个数
    clk_div   :integer:=4       --时钟分频比
    );
port(
    clkin                   :in std_logic;
    rst_n                   :in std_logic;
----------------------------------------------------    
    s_axis_tvalid           :in std_logic;
    s_axis_tready           :out std_logic;
    s_axis_tdata            :in std_logic_vector(device_num*8-1 downto 0);
-----------------------------------------------------    
    mr_n                    :out std_logic;             ---复位信号
    shcp                    :out std_logic;             ---移位寄存器时钟输入
    stcp                    :out std_logic;             ---锁存器锁存时钟
    oe_n                    :out std_logic;             ---输出使能
    ds                      :out std_logic              ---串行数据输入
);
end ctrl_74hc595;


architecture behav of ctrl_74hc595 is

signal cnt0:integer range 0 to clk_div-1;
signal cnt_tx:integer range 0 to device_num*8;
signal s1:integer range 0 to 3;

signal s_axis_tready_buf:std_logic;
signal tx_over:std_logic;
signal tx_data:std_logic_vector(device_num*8-1 downto 0);

begin


-------------------产生时钟逻辑------------------------

process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt0<=0;
        shcp<='0';
    else
        if rising_edge(clkin) then
            if cnt0>=clk_div-1 then
                shcp<='0';
            elsif cnt0=clk_div/2-1 then
                shcp<='1';
            end if;
            
            if s1=0 then
                cnt0<=0;
            else
                if cnt0>= clk_div-1 then
                    cnt0<=0;
                else
                    cnt0<=cnt0+1;
                end if;
            end if;
        end if;
    end if;
end process;
                
------------------移位控制逻辑--------------------------------------------------
s_axis_tready<=s_axis_tready_buf;
mr_n<=rst_n;
oe_n<='0';
process(clkin,rst_n)
begin
    if rst_n='0' then
        cnt_tx<=0;
        s1<=0;
        s_axis_tready_buf<='0';
        tx_data<=(others=>'0');
        tx_over<='0';
        ds<='0';
        stcp<='0';
    else
        if rising_edge(clkin) then
            case s1 is
                when 0=>
                    if s_axis_tvalid='1' and s_axis_tready_buf='1' then
                        s1<=1;
                        tx_data<=s_axis_tdata;
                        s_axis_tready_buf<='0';
                    else
                        s_axis_tready_buf<='1';
                        s1<=s1;
                    end if;
                    cnt_tx<=0;
                    tx_over<='0';
                
                when 1=>
                    if cnt0=clk_div-1 then
                        ds<=tx_data(device_num*8-1-cnt_tx);
                        cnt_tx<=cnt_tx+1;
                        s1<=2;
                    end if;
                    stcp<='0';
                    
                when 2=>
                    if cnt0=clk_div-1 then
                        ds<=tx_data(device_num*8-1-cnt_tx);
                        cnt_tx<=cnt_tx+1;
                    end if;
                 
                    -- if cnt0>=clk_div-1 then
                        -- stcp<='1';
                    -- elsif cnt0=clk_div/2-1 then
                        -- stcp<='0';
                    -- end if;
                        
                    if cnt0=clk_div-1 and cnt_tx=device_num*8-1 then
                        tx_over<='1';
                    end if;

                    if tx_over='1' and cnt0=clk_div/2-1 then
                        s1<=3;
                    end if;
                
                when 3=>
                    if cnt0>=clk_div-1 then
                        stcp<='1';
                    elsif cnt0=clk_div/2-1 then
                        stcp<='0';
                        s1<=0;
                    end if;                   
                
                
                when others=>
                    s1<=0;
            end case;
        end if;
    end if;
end process;






















end behav;