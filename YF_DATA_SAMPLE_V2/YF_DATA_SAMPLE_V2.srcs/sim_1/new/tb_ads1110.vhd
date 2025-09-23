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
use STD.TEXTIO.ALL; -- ���ڱ���͵���

-- ===========================================================================
-- ADS1110��ȡ������ƽ̨
-- ���ܣ�
--   1. �ṩʱ�Ӻ͸�λ����
--   2. ģ��ADS1110��I2C��Ӧ��Ϊ
--   3. ִ���Զ���������
--   4. ��֤���������������״̬
-- ===========================================================================
entity tb_ads1110 is
end tb_ads1110;

architecture Behavioral of tb_ads1110 is
    -- ���ⵥԪ�������
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

    -- �����ź�����
    signal clkin        : STD_LOGIC := '0';       -- ϵͳʱ�� (50MHz)
    signal rst_n        : STD_LOGIC := '0';       -- ��λ�ź� (����Ч)
    signal start_read   : STD_LOGIC := '0';       -- ������ȡ�ź�
    signal sda          : STD_LOGIC := 'Z';       -- I2C������ (˫��)
    signal scl          : STD_LOGIC;              -- I2Cʱ����
    signal data_out     : STD_LOGIC_VECTOR(15 downto 0); -- ADC�������
    signal data_ready   : STD_LOGIC;              -- ���ݾ����ź�
    signal error_flag        : STD_LOGIC;              -- ����ָʾ�ź�
    
    -- I2C�ӻ�ģ���ź�
    signal i2c_slave_data : STD_LOGIC_VECTOR(15 downto 0) := x"ABCD"; -- ģ��ADC����ֵ
    
    -- ���Կ��Ʋ���
    constant CLK_PERIOD : time := 20 ns;          -- 50MHzʱ������ (20ns)
    signal test_passed  : boolean := false;       -- ������ɱ�־

    -- =======================================================================
    -- �Զ���ʮ������ת������
    -- ���ܣ���std_logic_vectorת��Ϊʮ�������ַ���
    -- ��;���ڱ�����Ϣ����ʾʮ������ֵ
    -- =======================================================================
    function to_hex_string(slv : std_logic_vector) return string is
        variable hexlen : integer;                  -- ʮ�������ַ�����
        variable longslv : std_logic_vector(67 downto 0) := (others => '0'); -- ��չ����
        variable hex : string(1 to 16);             -- ����ַ���
        variable fourbit : std_logic_vector(3 downto 0); -- 4λ����
    begin
        hexlen := (slv'length + 3)/4;             -- ���������ַ���
        longslv(slv'length-1 downto 0) := slv;    -- ������������
        
        -- ÿ4λת��Ϊһ��ʮ�������ַ�
        for i in 0 to hexlen-1 loop
            fourbit := longslv(i*4+3 downto i*4); -- ��ȡ4λ
            case fourbit is                       -- 4λ��ʮ������ӳ��
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
                when others => hex(hexlen-i) := '?'; -- ������
            end case;
        end loop;
        return "0x" & hex(1 to hexlen); -- ����ʮ�����Ƹ�ʽ�ַ���
    end function;

begin
    -- =======================================================================
    -- ʵ�������ⵥԪ (UUT)
    -- =======================================================================
    uut: ADS1110_Reader
        port map (
            clkin => clkin,         -- 50MHzϵͳʱ��
            rst_n => rst_n,         -- ��λ�ź�
            start_read => start_read, -- ������ȡ�ź�
            sda => sda,             -- I2C������
            scl => scl,             -- I2Cʱ����
            data_out => data_out,   -- ADC�������
            data_ready => data_ready, -- ���ݾ����ź�
            error_flag => error_flag          -- ����ָʾ
        );

    -- =======================================================================
    -- ʱ�����ɽ���
    -- ���ܣ�����50MHzϵͳʱ�� (����20ns)
    -- ˵�����������ʱ�Զ�ֹͣ (test_passed=true)
    -- =======================================================================
    clk_process: process
    begin
        while not test_passed loop       -- ����δ���ʱ��������
            clkin <= '0';                -- 10ns�͵�ƽ
            wait for CLK_PERIOD/2;       
            clkin <= '1';                -- 10ns�ߵ�ƽ
            wait for CLK_PERIOD/2;       
        end loop;
        wait; -- ������ɺ�ֹͣ
    end process;

    -- =======================================================================
    -- I2C�ӻ�ģ�����
    -- ���ܣ�ģ��ADS1110��I2C��Ӧ��Ϊ
    -- Э��ʵ�֣�
    --   1. ���START/STOP����
    --   2. ��Ӧ�豸��ַ
    --   3. ����ģ��ADC����
    --   4. ����ACK/NACK
    -- =======================================================================
    i2c_slave_process: process
        variable data_byte   : STD_LOGIC_VECTOR(7 downto 0); -- �����ֽڻ���
    begin
        sda <= 'Z'; -- Ĭ�ϸ���̬ (�ͷ�����)
        -- ����1: �ȴ�START���� (SCL�ߵ�ƽʱSDA�½���)
        wait until scl = '1' and sda'event and sda = '0';
        report "[I2C Slave] START condition detected" severity note;
        
        -- ����2: ���յ�ַ�ֽ�(дģʽ) - 8λ (MSB first)
        for i in 7 downto 0 loop
            wait until rising_edge(scl); -- ��SCL�����ز���SDA
            data_byte(i) := sda;        -- �洢���յ���λ
        end loop;
        
        -- ����3: ����ACK��Ӧ
        -- wait until falling_edge(scl);   -- ��SCL�½��ؿ�ʼ��Ӧ
        -- sda <= '0';                    -- ����ACK (����SDA)
        -- wait until rising_edge(scl);    -- ����ACKֱ��SCL������
        -- sda <= 'Z';                    -- �ͷ�SDA
		
		wait until falling_edge(scl);   -- ��SCL�½��ؿ�ʼ��Ӧ
		sda <= '0';                    -- ����ACK (����SDA)
		wait until rising_edge(scl);    -- ����ACKֱ��SCL������
		-- wait until falling_edge(scl);   -- �ȴ�SCL�½������ͷ�  <-- ��Ӵ˵ȴ�
		-- sda <= 'Z';                    -- �ͷ�SDA
        
        -- ����4: �ȴ�REPEAT START����
        -- wait until scl = '1' and sda'event and sda = '0';
        -- report "[I2C Slave] REPEAT START detected" severity note;
        
        -- ����5: ���յ�ַ�ֽ�(��ģʽ) - 8λ
        -- for i in 7 downto 0 loop
            -- wait until rising_edge(scl);
            -- data_byte(i) := sda;
        -- end loop;
        
        -- ����6: ����ACK��Ӧ
		-- wait until falling_edge(scl);   -- ��SCL�½��ؿ�ʼ��Ӧ
		-- sda <= '0';                    -- ����ACK (����SDA)
		-- wait until rising_edge(scl);    -- ����ACKֱ��SCL������
		-- wait until falling_edge(scl);   -- �ȴ�SCL�½������ͷ�  <-- ��Ӵ˵ȴ�
		-- sda <= 'Z';                    -- �ͷ�SDA
        
        -- ����7: �������� (MSB first)
        -- �ȷ��͸��ֽ�(MSB)���ٷ��͵��ֽ�(LSB)
		    for bit_num in 7 downto 0 loop
                wait until falling_edge(scl); -- ��SCL�½��ظ�������
                -- ��ģ����������ȡ��Ӧλ (MSB first)
                sda <= i2c_slave_data(8 + bit_num);
            end loop;
			wait until falling_edge(scl);      -- 
			sda<='Z';
			wait until rising_edge(scl);      -- 
		    if sda = '1' then                -- ���NACK (SDA�ߵ�ƽ)
                report "[I2C Slave] NACK received, stopping transmission" severity note;
            else
                report "[I2C Slave] ACK received, continuing" severity note;
            end if;
		
		    for bit_num in 7 downto 0 loop
                wait until falling_edge(scl); -- ��SCL�½��ظ�������
                -- ��ģ����������ȡ��Ӧλ (MSB first)
                sda <= i2c_slave_data(0 + bit_num);
            end loop;
			wait until falling_edge(scl);      
		    sda<='Z';
			wait until rising_edge(scl);      -- 
		    if sda = '1' then                -- ���NACK (SDA�ߵ�ƽ)
                report "[I2C Slave] NACK received, stopping transmission" severity note;
            else
                report "[I2C Slave] ACK received, continuing" severity note;
            end if;		
		
        -- for byte_num in 1 downto 0 loop
            -- for bit_num in 7 downto 0 loop
                -- wait until falling_edge(scl); -- ��SCL�½��ظ�������
                --��ģ����������ȡ��Ӧλ (MSB first)
                -- sda <= i2c_slave_data(byte_num*8 + bit_num);
            -- end loop;
            
            --����8: �ȴ�����ACK/NACK
            -- wait until rising_edge(scl);      -- ��SCL�����ؼ��ACK
            -- if sda = '1' then                -- ���NACK (SDA�ߵ�ƽ)
                -- report "[I2C Slave] NACK received, stopping transmission" severity note;
                -- exit; -- �յ�NACK��ֹͣ����
            -- else
                -- report "[I2C Slave] ACK received, continuing" severity note;
            -- end if;
        -- end loop;
        
        -- ����9: �ȴ�STOP���� (SCL�ߵ�ƽʱSDA������)
        wait until scl = '1' and sda'event and sda = '1';
        report "[I2C Slave] STOP condition detected" severity note;
        sda <= 'Z'; -- ȷ���ͷ�����
    end process;

    -- =======================================================================
    -- ����������
    -- ���ܣ����Ʋ������У�ִ�в��԰�������֤���
    -- ���԰�����
    --   1. ������ȡ���� (Ԥ��ֵ0xABCD)
    --   2. ���ݸı���� (Ԥ��ֵ0x1234)
    -- =======================================================================
    stimulus_process: process
    begin
        -- ��ʼ���׶�
        report "===== Testbench Initialization =====" severity note;
        report "Applying reset..." severity note;
        rst_n <= '0';            -- ���λ
        wait for 100 ns;          -- ���ָ�λ100ns
        rst_n <= '1';             -- �ͷŸ�λ
        report "Reset released" severity note;
        wait for CLK_PERIOD*1;   -- �ȴ�10��ʱ������ (�ȶ�״̬)
        i2c_slave_data <= x"ABCD"; -- ����ģ������
        -- ===================================================================
        -- ���԰���1: ������ȡ
        -- Ŀ�ģ���֤������ȡ����
        -- Ԥ�ڣ���ȡ��ģ��ֵ0xABCD
        -- ===================================================================
        report "===== Test Case 1: Normal Read Operation =====" severity note;
        report "Expecting: 0xABCD" severity note;
        start_read <= '1';         -- ������ȡ
        wait for CLK_PERIOD*1;       -- ����һ��ʱ������
        start_read <= '0';         -- ��������ź�
        
        -- �ȴ����ݾ����ź�
        report "Waiting for data_ready..." severity note;
        wait until data_ready = '1';
        
        -- ��֤�������
        assert data_out = x"ABCD" 
            report "Test 1 Failed: Expected 0xABCD, got " & to_hex_string(data_out)
            severity error;
        report "Test 1 Passed: Correct data received" severity note;
        
        -- ���Լ��
        wait for CLK_PERIOD*100;    -- �ȴ�10��ʱ������
        
        -- ===================================================================
        -- ���԰���2: ���ݸı����
        -- Ŀ�ģ���֤��ȡ��ͬ���ݵ�����
        -- Ԥ�ڣ���ȡ���޸ĺ��ֵ0x1234
        -- ===================================================================
        report "===== Test Case 2: Changed Data Read =====" severity note;
        i2c_slave_data <= x"1234"; -- ����ģ������
        report "Changed simulated data to 0x1234" severity note;
        start_read <= '1';         -- ������ȡ
        wait for CLK_PERIOD;
        start_read <= '0';
        
        -- �ȴ����ݾ���
        report "Waiting for data_ready..." severity note;
        wait until data_ready = '1';
        
        -- ��֤�������
        assert data_out = x"1234" 
            report "Test 2 Failed: Expected 0x1234, got " & to_hex_string(data_out)
            severity error;
        report "Test 2 Passed: Correct data received" severity note;
        
        -- ===================================================================
        -- �������
        -- ===================================================================
        test_passed <= true;       -- ������ɱ�־��ֹͣʱ��
        report "#############################################" severity note;
        report "# All tests completed successfully" severity note;
        report "#############################################" severity note;
        wait; -- ����ֹͣ
    end process;

    -- =======================================================================
    -- �����ؽ���
    -- ���ܣ����error�źţ����ͨ�Ŵ���
    -- ˵������error�źű��ʱ�����������
    -- =======================================================================
    error_monitor: process
    begin
        wait until error_flag='1';    -- �ȴ�������
        report "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" severity error;
        report "! I2C error_flag detected during communication !" severity error;
        report "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" severity error;
        wait; -- ����ֹͣ
    end process;
end Behavioral;

