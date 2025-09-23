----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2025/07/19 11:16:46
-- Design Name: 
-- Module Name: tb_ads1110 - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL; -- 用于报告和调试

-- ===========================================================================
-- ADS1110读取器测试平台
-- 功能：
--   1. 提供时钟和复位激励
--   2. 模拟ADS1110的I2C响应行为
--   3. 执行自动测试序列
--   4. 验证输出结果并报告测试状态
-- ===========================================================================
entity tb_ads1110 is
end tb_ads1110;

architecture Behavioral of tb_ads1110 is
    -- 被测单元组件声明
    component ADS1110_Reader
        Port (
            clkin       : in  STD_LOGIC;
            rst_n       : in  STD_LOGIC;
            start_read  : in  STD_LOGIC;
            sda         : inout STD_LOGIC;
            scl         : out STD_LOGIC;
            data_out    : out STD_LOGIC_VECTOR(15 downto 0);
            data_ready  : out STD_LOGIC;
            error_flag       : out STD_LOGIC
        );
    end component;

    -- 测试信号声明
    signal clkin        : STD_LOGIC := '0';       -- 系统时钟 (50MHz)
    signal rst_n        : STD_LOGIC := '0';       -- 复位信号 (低有效)
    signal start_read   : STD_LOGIC := '0';       -- 启动读取信号
    signal sda          : STD_LOGIC := 'Z';       -- I2C数据线 (双向)
    signal scl          : STD_LOGIC;              -- I2C时钟线
    signal data_out     : STD_LOGIC_VECTOR(15 downto 0); -- ADC输出数据
    signal data_ready   : STD_LOGIC;              -- 数据就绪信号
    signal error_flag        : STD_LOGIC;              -- 错误指示信号
    
    -- I2C从机模拟信号
    signal i2c_slave_data : STD_LOGIC_VECTOR(15 downto 0) := x"ABCD"; -- 模拟ADC返回值
    
    -- 测试控制参数
    constant CLK_PERIOD : time := 20 ns;          -- 50MHz时钟周期 (20ns)
    signal test_passed  : boolean := false;       -- 测试完成标志

    -- =======================================================================
    -- 自定义十六进制转换函数
    -- 功能：将std_logic_vector转换为十六进制字符串
    -- 用途：在报告消息中显示十六进制值
    -- =======================================================================
    function to_hex_string(slv : std_logic_vector) return string is
        variable hexlen : integer;                  -- 十六进制字符长度
        variable longslv : std_logic_vector(67 downto 0) := (others => '0'); -- 扩展向量
        variable hex : string(1 to 16);             -- 结果字符串
        variable fourbit : std_logic_vector(3 downto 0); -- 4位分组
    begin
        hexlen := (slv'length + 3)/4;             -- 计算所需字符数
        longslv(slv'length-1 downto 0) := slv;    -- 复制输入向量
        
        -- 每4位转换为一个十六进制字符
        for i in 0 to hexlen-1 loop
            fourbit := longslv(i*4+3 downto i*4); -- 提取4位
            case fourbit is                       -- 4位到十六进制映射
                when "0000" => hex(hexlen-i) := '0';
                when "0001" => hex(hexlen-i) := '1';
                when "0010" => hex(hexlen-i) := '2';
                when "0011" => hex(hexlen-i) := '3';
                when "0100" => hex(hexlen-i) := '4';
                when "0101" => hex(hexlen-i) := '5';
                when "0110" => hex(hexlen-i) := '6';
                when "0111" => hex(hexlen-i) := '7';
                when "1000" => hex(hexlen-i) := '8';
                when "1001" => hex(hexlen-i) := '9';
                when "1010" => hex(hexlen-i) := 'A';
                when "1011" => hex(hexlen-i) := 'B';
                when "1100" => hex(hexlen-i) := 'C';
                when "1101" => hex(hexlen-i) := 'D';
                when "1110" => hex(hexlen-i) := 'E';
                when "1111" => hex(hexlen-i) := 'F';
                when others => hex(hexlen-i) := '?'; -- 错误处理
            end case;
        end loop;
        return "0x" & hex(1 to hexlen); -- 返回十六进制格式字符串
    end function;

begin
    -- =======================================================================
    -- 实例化被测单元 (UUT)
    -- =======================================================================
    uut: ADS1110_Reader
        port map (
            clkin => clkin,         -- 50MHz系统时钟
            rst_n => rst_n,         -- 复位信号
            start_read => start_read, -- 启动读取信号
            sda => sda,             -- I2C数据线
            scl => scl,             -- I2C时钟线
            data_out => data_out,   -- ADC输出数据
            data_ready => data_ready, -- 数据就绪信号
            error_flag => error_flag          -- 错误指示
        );

    -- =======================================================================
    -- 时钟生成进程
    -- 功能：产生50MHz系统时钟 (周期20ns)
    -- 说明：测试完成时自动停止 (test_passed=true)
    -- =======================================================================
    clk_process: process
    begin
        while not test_passed loop       -- 测试未完成时持续运行
            clkin <= '0';                -- 10ns低电平
            wait for CLK_PERIOD/2;       
            clkin <= '1';                -- 10ns高电平
            wait for CLK_PERIOD/2;       
        end loop;
        wait; -- 测试完成后停止
    end process;

    -- =======================================================================
    -- I2C从机模拟进程
    -- 功能：模拟ADS1110的I2C响应行为
    -- 协议实现：
    --   1. 检测START/STOP条件
    --   2. 响应设备地址
    --   3. 发送模拟ADC数据
    --   4. 处理ACK/NACK
    -- =======================================================================
    i2c_slave_process: process
        variable data_byte   : STD_LOGIC_VECTOR(7 downto 0); -- 接收字节缓冲
    begin
        sda <= 'Z'; -- 默认高阻态 (释放总线)
        -- 步骤1: 等待START条件 (SCL高电平时SDA下降沿)
        wait until scl = '1' and sda'event and sda = '0';
        report "[I2C Slave] START condition detected" severity note;
        
        -- 步骤2: 接收地址字节(写模式) - 8位 (MSB first)
        for i in 7 downto 0 loop
            wait until rising_edge(scl); -- 在SCL上升沿采样SDA
            data_byte(i) := sda;        -- 存储接收到的位
        end loop;
        
        -- 步骤3: 发送ACK响应
        -- wait until falling_edge(scl);   -- 在SCL下降沿开始响应
        -- sda <= '0';                    -- 发送ACK (拉低SDA)
        -- wait until rising_edge(scl);    -- 保持ACK直到SCL上升沿
        -- sda <= 'Z';                    -- 释放SDA
		
		wait until falling_edge(scl);   -- 在SCL下降沿开始响应
		sda <= '0';                    -- 发送ACK (拉低SDA)
		wait until rising_edge(scl);    -- 保持ACK直到SCL上升沿
		-- wait until falling_edge(scl);   -- 等待SCL下降沿再释放  <-- 添加此等待
		-- sda <= 'Z';                    -- 释放SDA
        
        -- 步骤4: 等待REPEAT START条件
        -- wait until scl = '1' and sda'event and sda = '0';
        -- report "[I2C Slave] REPEAT START detected" severity note;
        
        -- 步骤5: 接收地址字节(读模式) - 8位
        -- for i in 7 downto 0 loop
            -- wait until rising_edge(scl);
            -- data_byte(i) := sda;
        -- end loop;
        
        -- 步骤6: 发送ACK响应
		-- wait until falling_edge(scl);   -- 在SCL下降沿开始响应
		-- sda <= '0';                    -- 发送ACK (拉低SDA)
		-- wait until rising_edge(scl);    -- 保持ACK直到SCL上升沿
		-- wait until falling_edge(scl);   -- 等待SCL下降沿再释放  <-- 添加此等待
		-- sda <= 'Z';                    -- 释放SDA
        
        -- 步骤7: 发送数据 (MSB first)
        -- 先发送高字节(MSB)，再发送低字节(LSB)
		    for bit_num in 7 downto 0 loop
                wait until falling_edge(scl); -- 在SCL下降沿更新数据
                -- 从模拟数据中提取对应位 (MSB first)
                sda <= i2c_slave_data(8 + bit_num);
            end loop;
			wait until falling_edge(scl);      -- 
			sda<='Z';
			wait until rising_edge(scl);      -- 
		    if sda = '1' then                -- 检测NACK (SDA高电平)
                report "[I2C Slave] NACK received, stopping transmission" severity note;
            else
                report "[I2C Slave] ACK received, continuing" severity note;
            end if;
		
		    for bit_num in 7 downto 0 loop
                wait until falling_edge(scl); -- 在SCL下降沿更新数据
                -- 从模拟数据中提取对应位 (MSB first)
                sda <= i2c_slave_data(0 + bit_num);
            end loop;
			wait until falling_edge(scl);      
		    sda<='Z';
			wait until rising_edge(scl);      -- 
		    if sda = '1' then                -- 检测NACK (SDA高电平)
                report "[I2C Slave] NACK received, stopping transmission" severity note;
            else
                report "[I2C Slave] ACK received, continuing" severity note;
            end if;		
		
        -- for byte_num in 1 downto 0 loop
            -- for bit_num in 7 downto 0 loop
                -- wait until falling_edge(scl); -- 在SCL下降沿更新数据
                --从模拟数据中提取对应位 (MSB first)
                -- sda <= i2c_slave_data(byte_num*8 + bit_num);
            -- end loop;
            
            --步骤8: 等待主机ACK/NACK
            -- wait until rising_edge(scl);      -- 在SCL上升沿检查ACK
            -- if sda = '1' then                -- 检测NACK (SDA高电平)
                -- report "[I2C Slave] NACK received, stopping transmission" severity note;
                -- exit; -- 收到NACK则停止发送
            -- else
                -- report "[I2C Slave] ACK received, continuing" severity note;
            -- end if;
        -- end loop;
        
        -- 步骤9: 等待STOP条件 (SCL高电平时SDA上升沿)
        wait until scl = '1' and sda'event and sda = '1';
        report "[I2C Slave] STOP condition detected" severity note;
        sda <= 'Z'; -- 确保释放总线
    end process;

    -- =======================================================================
    -- 主测试流程
    -- 功能：控制测试序列，执行测试案例并验证结果
    -- 测试案例：
    --   1. 正常读取测试 (预期值0xABCD)
    --   2. 数据改变测试 (预期值0x1234)
    -- =======================================================================
    stimulus_process: process
    begin
        -- 初始化阶段
        report "===== Testbench Initialization =====" severity note;
        report "Applying reset..." severity note;
        rst_n <= '0';            -- 激活复位
        wait for 100 ns;          -- 保持复位100ns
        rst_n <= '1';             -- 释放复位
        report "Reset released" severity note;
        wait for CLK_PERIOD*1;   -- 等待10个时钟周期 (稳定状态)
        i2c_slave_data <= x"ABCD"; -- 更改模拟数据
        -- ===================================================================
        -- 测试案例1: 正常读取
        -- 目的：验证基本读取功能
        -- 预期：读取到模拟值0xABCD
        -- ===================================================================
        report "===== Test Case 1: Normal Read Operation =====" severity note;
        report "Expecting: 0xABCD" severity note;
        start_read <= '1';         -- 启动读取
        wait for CLK_PERIOD*1;       -- 保持一个时钟周期
        start_read <= '0';         -- 清除启动信号
        
        -- 等待数据就绪信号
        report "Waiting for data_ready..." severity note;
        wait until data_ready = '1';
        
        -- 验证输出数据
        assert data_out = x"ABCD" 
            report "Test 1 Failed: Expected 0xABCD, got " & to_hex_string(data_out)
            severity error;
        report "Test 1 Passed: Correct data received" severity note;
        
        -- 测试间隔
        wait for CLK_PERIOD*100;    -- 等待10个时钟周期
        
        -- ===================================================================
        -- 测试案例2: 数据改变测试
        -- 目的：验证读取不同数据的能力
        -- 预期：读取到修改后的值0x1234
        -- ===================================================================
        report "===== Test Case 2: Changed Data Read =====" severity note;
        i2c_slave_data <= x"1234"; -- 更改模拟数据
        report "Changed simulated data to 0x1234" severity note;
        start_read <= '1';         -- 启动读取
        wait for CLK_PERIOD;
        start_read <= '0';
        
        -- 等待数据就绪
        report "Waiting for data_ready..." severity note;
        wait until data_ready = '1';
        
        -- 验证输出数据
        assert data_out = x"1234" 
            report "Test 2 Failed: Expected 0x1234, got " & to_hex_string(data_out)
            severity error;
        report "Test 2 Passed: Correct data received" severity note;
        
        -- ===================================================================
        -- 测试完成
        -- ===================================================================
        test_passed <= true;       -- 设置完成标志，停止时钟
        report "#############################################" severity note;
        report "# All tests completed successfully" severity note;
        report "#############################################" severity note;
        wait; -- 永久停止
    end process;

    -- =======================================================================
    -- 错误监控进程
    -- 功能：监控error信号，检测通信错误
    -- 说明：当error信号变高时立即报告错误
    -- =======================================================================
    error_monitor: process
    begin
        wait until error_flag='1';    -- 等待错误发生
        report "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" severity error;
        report "! I2C error_flag detected during communication !" severity error;
        report "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" severity error;
        wait; -- 永久停止
    end process;
end Behavioral;

