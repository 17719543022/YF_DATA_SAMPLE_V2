library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ===========================================================================
-- ADS1110 I2C ��ȡ��ʵ��
-- ���ܣ�ͨ��I2C�ӿڴ�ADS1110 ADCоƬ��ȡ16λת�����
-- ��Ҫ�ص㣺
--   1. ֧��400kHz I2C����ģʽ
--   2. ������״̬��ʵ��I2CЭ��
--   3. �Զ�����START/STOP/REPEAT START����
--   4. ���ô��������
-- ===========================================================================
entity ADS1110_Reader is
	generic(device_addr:std_logic_vector(2 downto 0):="000");
    Port (
        clkin       : in  STD_LOGIC;        -- ϵͳʱ������ (50MHz)
        rst_n       : in  STD_LOGIC;        -- �첽�͵�ƽ��Ч��λ�ź� (0=��λ)
        start_read  : in  STD_LOGIC;        -- ������ȡ�ź� (�ߵ�ƽ������������)
        sda         : inout STD_LOGIC;      -- I2C ������ (˫�����ⲿ����)
        scl         : out STD_LOGIC;        -- I2C ʱ���� (��������ⲿ����)
        data_out    : out STD_LOGIC_VECTOR(15 downto 0); -- ��ȡ��16λADCֵ
        data_ready  : out STD_LOGIC;        -- ���ݾ����ź� (�ߵ�ƽ��ʱ������)
        error_flag       : out STD_LOGIC         -- ͨ�Ŵ���ָʾ (�ߵ�ƽ��Ч�����ֵ��´β���)
    );
end ADS1110_Reader;

architecture Behavioral of ADS1110_Reader is
    -- =======================================================================
    -- I2C �豸��ַ����
    -- ADS1110Ĭ�ϵ�ַ��1001000 (ADDR0�ӵ�)
    -- ע�⣺��ַ�ֽڰ���R/Wλ (���λ)
    -- =======================================================================
    constant I2C_ADDR    : STD_LOGIC_VECTOR(7 downto 0) := "1001"&device_addr&'0'; -- дģʽ��ַ (R/W=0)
    constant I2C_ADDR_RD : STD_LOGIC_VECTOR(7 downto 0) := "1001"&device_addr&'1'; -- ��ģʽ��ַ (R/W=1)

    -- =======================================================================
    -- I2C ����״̬������
    -- ����ʵ��I2CЭ�����������״̬
    -- =======================================================================
	signal s1:integer  range 0 to 15;

    -- =======================================================================
    -- I2C ʱ�ӷ�Ƶ����
    -- ϵͳʱ��50MHz��ƵΪ400kHz I2Cʱ��
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
    -- ���ݺͿ����ź�
    -- =======================================================================
    signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- ������λ�Ĵ���
    signal rx_data_temp : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); --���ݽ��ռĴ���
	
    signal bit_cnt : integer range 0 to 15 := 0; -- λ������ (0-7, ÿ���ֽ�8λ)
    
    -- SDA�źŻ���
    signal sda_out : STD_LOGIC; -- SDA���ֵ
    signal sda_in  : STD_LOGIC; -- SDA����ֵ
    
    signal scl_out : STD_LOGIC; -- SCL�������
    signal sda_oe  : STD_LOGIC; -- SDA���ʹ�� (1=��������SDA, 0=����̬)
    signal ACK     : STD_LOGIC; -- 

begin
    -- =======================================================================
    -- I2C ʱ�ӷ�Ƶ��
    -- ���ܣ���50MHzϵͳʱ�ӷ�Ƶ����400kHz��I2Cʱ��ʹ���ź�
    -- ˵����ÿ��I2Cʱ�����ڲ���һ��ʱ��ʹ������
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
    -- I2C ������̬����
    -- ���ܣ�����SDA�ߵķ������
    -- ˵������sda_oe=1ʱ����������SDA�ߣ���sda_oe=0ʱ��SDAΪ����̬���ӻ��ɿ���
    -- =======================================================================
    sda <= sda_out when sda_oe = '1' else 'Z'; -- ��̬�ſ���
    sda_in <= sda;                            -- ���뻺��
    
    -- SCL������ƣ�����״̬���ָߵ�ƽ������״̬��״̬������
    scl <= scl_out ;

    -- =======================================================================
    -- ��״̬�����ƽ���
    -- ���ܣ�ʵ��������I2CЭ��״̬��
    -- �ص㣺
    --  1. ʹ��ϵͳʱ��(clkin)�����ش���
    --  2. ����i2c_clk_en��Чʱ����״̬ (400kHz)
    --  3. �ϸ���ѭI2CЭ��ʱ��Ҫ��
    -- =======================================================================
    process(clkin, rst_n)
    begin
        -- �첽��λ
        if rst_n = '0' then
            -- ��λ״̬��ʼ��
            sda_out <= '1';          -- SDAĬ�ϸ�
            sda_oe <= '0';           -- �ͷ�SDA����
            bit_cnt <= 0;            -- λ����������
            rx_data_temp <= (others => '0'); -- �����������
            data_out <= (others => '0'); -- �����������
            data_ready <= '0';       -- ��������ź�
            error_flag <= '0';            -- ��������־
            i2c_working<='0';
			s1<=0;
        -- ϵͳʱ�������ش���
        elsif rising_edge(clkin) then
            -- ״̬�����߼�
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
				when 1=>  --��ʼ״̬
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
							sda_oe<='0';	 ---�ͷ����ߣ���������
						else
							s1<=0;
						end if;
					end if;
				
				when 4=>				---���ո�8bit����
					if scl_pos_mid='1' then
						rx_data_temp(15-bit_cnt)<= sda_in;
						bit_cnt<=bit_cnt+1;
						if bit_cnt>=7 then
							s1<=5;
						else
							s1<=s1;
						end if;
					end if;
				
				when 5=>  --��������ACK
					if scl_neg='1' then
						sda_oe<='1';   	  --�������� ����ACK	
					end if;
					
					if scl_neg_mid='1' then
						sda_out<='0' ;
						s1<=6;
					end if;
				
				when 6=>
					if scl_neg='1' then
						sda_oe<='0';   	  --�ͷ����� �������ݵ�8λ;
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
				
				when 7=>  --��������ACK
					if scl_neg='1' then
						sda_oe<='1';   	  --�������� ����NCK	
					end if;
					if scl_neg_mid='1' then
						sda_out<='1' ;
						s1<=8;
					end if;
				
				when 8=>  -- --
					if scl_neg='1' then		--�ṩ������ACKʱ��
						s1<=9;
						sda_out<='0' ;
					end if;
				
				
				when 9=>
					if scl_pos_mid='1' then   --����ֹͣ����
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
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
					
					
					
					
					
					