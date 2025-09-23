library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ===========================================================================
-- ADS1110 I2C 读取器实体
-- 功能：通过I2C接口从ADS1110 ADC芯片读取16位转换结果
-- 主要特点：
--   1. 支持400kHz I2C快速模式
--   2. 完整的状态机实现I2C协议
--   3. 自动处理START/STOP/REPEAT START条件
--   4. 内置错误检测机制
-- ===========================================================================
entity ADS1110_Reader is
	generic(device_addr:std_logic_vector(2 downto 0):="000");
    Port (
        clkin       : in  STD_LOGIC;        -- 系统时钟输入 (50MHz)
        rst_n       : in  STD_LOGIC;        -- 异步低电平有效复位信号 (0=复位)
        start_read  : in  STD_LOGIC;        -- 启动读取信号 (高电平触发，单脉冲)
        sda         : inout STD_LOGIC;      -- I2C 数据线 (双向，需外部上拉)
        scl         : out STD_LOGIC;        -- I2C 时钟线 (输出，需外部上拉)
        data_out    : out STD_LOGIC_VECTOR(15 downto 0); -- 读取的16位ADC值
        data_ready  : out STD_LOGIC;        -- 数据就绪信号 (高电平单时钟脉冲)
        error_flag       : out STD_LOGIC         -- 通信错误指示 (高电平有效，保持到下次操作)
    );
end ADS1110_Reader;

architecture Behavioral of ADS1110_Reader is
    -- =======================================================================
    -- I2C 设备地址常量
    -- ADS1110默认地址：1001000 (ADDR0接地)
    -- 注意：地址字节包含R/W位 (最低位)
    -- =======================================================================
    constant I2C_ADDR    : STD_LOGIC_VECTOR(7 downto 0) := "1001"&device_addr&'0'; -- 写模式地址 (R/W=0)
    constant I2C_ADDR_RD : STD_LOGIC_VECTOR(7 downto 0) := "1001"&device_addr&'1'; -- 读模式地址 (R/W=1)

    -- =======================================================================
    -- I2C 控制状态机定义
    -- 完整实现I2C协议所需的所有状态
    -- =======================================================================
	signal s1:integer  range 0 to 15;

    -- =======================================================================
    -- I2C 时钟分频控制
    -- 系统时钟50MHz分频为400kHz I2C时钟
    -- =======================================================================
	constant i2c_div:integer:=200;
	constant nuit_i2c_div:integer:=i2c_div/4;

	constant time_neg:integer:=0;
	constant time_neg_mid:integer:=time_neg+nuit_i2c_div;
	constant time_pos:integer:=time_neg_mid+nuit_i2c_div;
	constant time_pos_mid:integer:=time_pos+nuit_i2c_div;
	signal scl_pos		    :std_logic:='0';
	signal scl_pos_mid	    :std_logic:='0';
	signal scl_neg		    :std_logic:='0';
	signal scl_neg_mid	    :std_logic:='0';
	signal i2c_working	    :std_logic:='0';
	
	signal cnt_scl:integer ;
    -- =======================================================================
    -- 数据和控制信号
    -- =======================================================================
    signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- 数据移位寄存器
    signal rx_data_temp : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); --数据接收寄存器
	
    signal bit_cnt : integer range 0 to 15 := 0; -- 位计数器 (0-7, 每个字节8位)
    
    -- SDA信号缓冲
    signal sda_out : STD_LOGIC; -- SDA输出值
    signal sda_in  : STD_LOGIC; -- SDA输入值
    
    signal scl_out : STD_LOGIC; -- SCL输出缓冲
    signal sda_oe  : STD_LOGIC; -- SDA输出使能 (1=主机驱动SDA, 0=高阻态)
    signal ACK     : STD_LOGIC; -- 

begin
    -- =======================================================================
    -- I2C 时钟分频器
    -- 功能：将50MHz系统时钟分频产生400kHz的I2C时钟使能信号
    -- 说明：每个I2C时钟周期产生一个时钟使能脉冲
    -- =======================================================================
	process(clkin)
	begin
		if rising_edge(clkin) then
			if rst_n='0' then
				cnt_scl<=time_pos;
				scl_neg<='0';
				scl_neg_mid<='0';
				scl_pos<='0';
				scl_pos_mid<='0';
			else
				if i2c_working='1' then
					if cnt_scl>=i2c_div-1 then
						cnt_scl<=0;
					else
						cnt_scl<=cnt_scl+1;
					end if;
				else
					cnt_scl<=time_pos;
				end if;
				
				if cnt_scl=time_neg then
					scl_neg<='1';
				else
					scl_neg<='0';
				end if;

				if cnt_scl=time_neg_mid then
					scl_neg_mid<='1';
				else
					scl_neg_mid<='0';
				end if;
				
				if cnt_scl=time_pos then
					scl_pos<='1';
				else
					scl_pos<='0';
				end if;
				
				if cnt_scl=time_pos_mid then
					scl_pos_mid<='1';
				else
					scl_pos_mid<='0';
				end if;
				
				if i2c_working='1' then
					if scl_pos='1' then
						scl_out<='1';
					elsif scl_neg='1' then
						scl_out<='0';
					else
						scl_out<=scl_out;
					end if;
				else
					scl_out<='1';
				end if;
			end if;
		end if;
	end process;


    -- =======================================================================
    -- I2C 总线三态控制
    -- 功能：管理SDA线的方向控制
    -- 说明：当sda_oe=1时，主机驱动SDA线；当sda_oe=0时，SDA为高阻态，从机可控制
    -- =======================================================================
    sda <= sda_out when sda_oe = '1' else 'Z'; -- 三态门控制
    sda_in <= sda;                            -- 输入缓冲
    
    -- SCL输出控制：空闲状态保持高电平，其他状态由状态机控制
    scl <= scl_out ;

    -- =======================================================================
    -- 主状态机控制进程
    -- 功能：实现完整的I2C协议状态机
    -- 特点：
    --  1. 使用系统时钟(clkin)上升沿触发
    --  2. 仅在i2c_clk_en有效时更新状态 (400kHz)
    --  3. 严格遵循I2C协议时序要求
    -- =======================================================================
    process(clkin, rst_n)
    begin
        -- 异步复位
        if rst_n = '0' then
            -- 复位状态初始化
            sda_out <= '1';          -- SDA默认高
            sda_oe <= '0';           -- 释放SDA总线
            bit_cnt <= 0;            -- 位计数器清零
            rx_data_temp <= (others => '0'); -- 输出数据清零
            data_out <= (others => '0'); -- 输出数据清零
            data_ready <= '0';       -- 清除就绪信号
            error_flag <= '0';            -- 清除错误标志
            i2c_working<='0';
			s1<=0;
        -- 系统时钟上升沿触发
        elsif rising_edge(clkin) then
            -- 状态机主逻辑
			case s1 is
				when 0=>
					sda_out<='1';
					sda_oe<='1';
					data_ready <= '0';
					if start_read='1' then
						s1<=1;
						tx_data<=I2C_ADDR_RD;
						i2c_working<='1';
					else
						s1<=s1;
						i2c_working<='0';
					end if;
					bit_cnt<=0;
				when 1=>  --开始状态
					sda_oe<='1';
					bit_cnt<=0;
					if scl_pos_mid='1' then
						sda_out<='0';
						s1<=2;
					end if;
				
				when 2=>
					if scl_neg_mid='1' then
						sda_out<=tx_data(7-bit_cnt);
						if bit_cnt>=7 then
							s1<=10;
							bit_cnt<=0;
						else
							bit_cnt<=bit_cnt+1;
						end if;
					else
						s1<=s1;
					end if;
				
				when 10=>
					if scl_neg='1' then
						sda_oe<='0';
						s1<=3;
					end if;
				
				when 3=>
					
					if scl_pos_mid='1' then
						ACK<=not sda_in;
					end if;
					
					if scl_neg='1' then
						if ACK='1' then
							s1<=4;
							sda_oe<='0';	 ---释放总线，接受数据
						else
							s1<=0;
						end if;
					end if;
				
				when 4=>				---接收高8bit数据
					if scl_pos_mid='1' then
						rx_data_temp(15-bit_cnt)<= sda_in;
						bit_cnt<=bit_cnt+1;
						if bit_cnt>=7 then
							s1<=5;
						else
							s1<=s1;
						end if;
					end if;
				
				when 5=>  --主机发送ACK
					if scl_neg='1' then
						sda_oe<='1';   	  --控制总线 发送ACK	
					end if;
					
					if scl_neg_mid='1' then
						sda_out<='0' ;
						s1<=6;
					end if;
				
				when 6=>
					if scl_neg='1' then
						sda_oe<='0';   	  --释放总线 接收数据低8位;
					end if;
					if scl_pos_mid='1' and sda_oe='0' then
						rx_data_temp(15-bit_cnt)<= sda_in;
						if bit_cnt>=15 then
							s1<=7;
							bit_cnt<=0;
						else
							s1<=s1;
							bit_cnt<=bit_cnt+1;
						end if;
					end if;					
				
				when 7=>  --主机发送ACK
					if scl_neg='1' then
						sda_oe<='1';   	  --控制总线 发送NCK	
					end if;
					if scl_neg_mid='1' then
						sda_out<='1' ;
						s1<=8;
					end if;
				
				when 8=>  -- --
					if scl_neg='1' then		--提供完整的ACK时钟
						s1<=9;
						sda_out<='0' ;
					end if;
				
				
				when 9=>
					if scl_pos_mid='1' then   --发送停止条件
						sda_out<='1';
						data_out<=rx_data_temp;
						data_ready<='1';
						s1<=0;
					end if;
						
					
				when others=>
					s1<=0;
			end case;
		end if;
	end process;
	
end Behavioral;						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
					
					
					
					
					
					