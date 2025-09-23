----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/11/13 18:09:21
-- Design Name: 
-- Module Name: my_package - Behavioral
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
-- use work.my_package.all;
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

 PACKAGE my_package IS
  
 TYPE new_array_1 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*1-1 downto 0);
 TYPE new_array_2 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*2-1 downto 0);
 TYPE new_array_3 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*3-1 downto 0);
 TYPE new_array_4 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*4-1 downto 0);
 TYPE new_array_5 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*5-1 downto 0);
 TYPE new_array_6 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*6-1 downto 0);
 TYPE new_array_7 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*7-1 downto 0);
 TYPE new_array_8 IS ARRAY ( NATURAL RANGE <>) OF std_logic_vector(8*8-1 downto 0);

 TYPE ad_buf_t IS ARRAY ( 0 to 35) OF std_logic_vector(8*3-1 downto 0);
 TYPE ad_buf_ts IS ARRAY ( 0 to 35) OF std_logic_vector(8*3-1 downto 0);
 TYPE cfg_data_t IS ARRAY ( 0 to 35) OF std_logic_vector(8-1 downto 0);
 
 function us_over_add(
	a:std_logic_vector;--第一个数
	b:std_logic_vector--第二个数
) return std_logic_vector ;

 function s_over_add(
	a:std_logic_vector;--第一个数
	b:std_logic_vector--第二个数
) return std_logic_vector ;

function or_r 	(a:std_logic_vector) return std_logic;
function and_r  (a:std_logic_vector) return std_logic;
function xor_r  (a:std_logic_vector) return std_logic;

function cut_round(
	din:std_logic_vector;
	cut_num:integer	
) return std_logic_vector;

function cut_hh1(
	din:std_logic_vector;
	cut_num:integer	
) return std_logic_vector;

function cut_hh2(
	din:std_logic_vector;
	cut_h:integer;
	cut_l:integer
) return std_logic_vector ;








END my_package;
--------------------------------------------------------------
package body my_package is

    function max(L, R: INTEGER) return INTEGER is
    begin
	if L > R then
	    return L;
	else
	    return R;
	end if;
    end;


 function us_over_add(
	a:std_logic_vector;--第一个数
	b:std_logic_vector--第二个数
) return std_logic_vector is
constant dw:integer:= max(a'length,b'length);
variable result:std_logic_vector(dw downto 0);
variable result1:std_logic_vector(dw-1 downto 0);
begin
	result:=unsigned(('0'&a))+unsigned(('0'&b));
	if result(dw)='1' then
		result1:=(others=>'1');
	else
		result1:=result(dw-1 downto 0);
	end if;
	
	return result1;
	
end us_over_add;



function s_over_add(
	a:std_logic_vector;--第一个数
	b:std_logic_vector--第二个数
) return std_logic_vector is
constant dw:integer:= max(a'length,b'length);
variable result:std_logic_vector(dw-1 downto 0);
variable result1:std_logic_vector(dw-1 downto 0);
begin
	result:=signed(a)+signed(b);
	if a(a'high)='0' and b(b'high)='0' and  result(result'high)='1' then
		result1(dw-1):='0';
		result1(dw-2 downto 0):=(others=>'1');
	elsif a(a'high)='1' and b(b'high)='1' and result(result'high)='0' then
		result1(dw-1):='1';
		result1(dw-2 downto 0):=(others=>'0');
	else
		result1:=result;
	end if;
	
	return result1;
	
end s_over_add;



function or_r (a:std_logic_vector) return std_logic is
variable result:std_logic:='0';
begin
    for i in  a'range loop
        result:=result or a(i);
    end loop;
    
    return result;
end or_r;


function and_r (a:std_logic_vector) return std_logic is
variable result:std_logic:='1';
begin
    for i in a'range loop
        result:=result and a(i);
    end loop;
    
    return result;
end and_r;

---a=(a xor 0)   not a=(a xor 1)-----------------------------
function xor_r(a:std_logic_vector) return std_logic is
variable result:std_logic:='0';
begin
    for i in a'range loop
        result:=result xor a(i);
    end loop;
    
    return result;
end xor_r;

--------------三种截位方法---------------------------------------------------------

function cut_round(
	din:std_logic_vector;
	cut_num:integer	
) return std_logic_vector is
constant dw:integer :=din'length;
constant dw_o:integer:=dw-cut_num;
constant bc_int:std_logic_vector(cut_num-2 downto 0):=(others=>'1');
variable result:std_logic_vector(dw_o-1 downto 0):=(others=>'0');
variable result1:std_logic_vector(dw-1 downto 0):=(others=>'0');
begin
	if din(din'high)='0' then
		result1:=signed(din)+unsigned(bc_int);
		result:=result1(dw-1 downto cut_num);
	else
		result1:=signed(din)+unsigned(bc_int);
		result:=result1(dw-1 downto cut_num)-1;
	end if;
	

	return result;
end cut_round;


function cut_hh1(
	din:std_logic_vector;
	cut_num:integer
) return std_logic_vector is
constant dw:integer :=din'length;
constant dw_o:integer:=dw-cut_num;
constant bc_int:std_logic_vector(cut_num-2 downto 0):=(others=>'1');
variable result:std_logic_vector(dw_o-1 downto 0):=(others=>'0');
variable result1:std_logic_vector(dw-1 downto 0):=(others=>'0');
begin
	result1:=din;
	if din(din'high)='0' then
		result:=result1(dw-1 downto cut_num );
	else
		result:=result1(dw-1 downto cut_num)+1;
	end if;

	return result;
end cut_hh1;


function cut_hh2(
	din:std_logic_vector;
	cut_h:integer;
	cut_l:integer
) return std_logic_vector is
constant dw:integer :=din'length;
variable din1:std_logic_vector(dw-1 downto 0):=(others=>'0');
variable result:std_logic_vector(cut_h-cut_l downto 0):=(others=>'0');
constant p1:std_logic_vector(dw-1 downto cut_h):=(others=>'1');
constant p0:std_logic_vector(dw-1 downto cut_h):=(others=>'0');

begin
	din1:=din;
	if (din1(dw-1 downto cut_h)=p1) or  (din1(dw-1 downto cut_h)=p0) then
		result:=din1(cut_h downto cut_l);
	elsif din1(dw-1)='1' then
		result(cut_h-cut_l):='1';
		result(cut_h-cut_l-1 downto 0):=(others=>'0');
	elsif din1(dw-1)='0' then
		result(cut_h-cut_l):='0';
		result(cut_h-cut_l-1 downto 0):=(others=>'1');		
	else 
		null;
	end if;
	
	return result;
	
end cut_hh2;





end package body my_package;

