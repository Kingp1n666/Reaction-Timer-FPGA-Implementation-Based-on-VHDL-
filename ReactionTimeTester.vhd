library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ReactionTimeTester is
    Port (
        -- 时钟与复位
        clk         : in  STD_LOGIC;      -- 连续时钟，24MHz
        reset       : in  STD_LOGIC;      -- 复位

        -- 矩阵输入
		  key_row         : in  STD_LOGIC_VECTOR(3 downto 0);    -- 4行
        key_col         : in  STD_LOGIC_VECTOR(3 downto 0);    -- 4列


        -- LED输出
        led         : out STD_LOGIC;      -- 指示灯
        led_row     : buffer STD_LOGIC_VECTOR (15 downto 0); -- LED矩阵行选
        led_col     : out STD_LOGIC_VECTOR (15 downto 0); -- LED矩阵列选

        -- 数码管输出
        seg         : out STD_LOGIC_VECTOR (7 downto 0);  -- 段选
        dig         : out STD_LOGIC_VECTOR (5 downto 0);  -- 字选

        -- 蜂鸣器
        buzzer      : out STD_LOGIC;      -- 蜂鸣器信号
		  
		  start     : in STD_LOGIC ;
        stop      : in STD_LOGIC 
		  
    );
end ReactionTimeTester;

architecture Behavioral of ReactionTimeTester is
    -- 状态机状态定义
    type state_type is (READY, RANDOM_DELAY, TIMING, DONE, VIOLATION);
    signal current_state: state_type := READY;
	 signal next_state : state_type;

	 -- 键盘传递信号
	 signal key_pressed : STD_LOGIC_VECTOR(15 downto 0);  -- 用于存储键盘扫描的状态

	 
	 --键盘去抖
	 signal key_debounce_counter : integer range 0 to 10000 := 0;  -- 去抖计时器
    signal key_stable : STD_LOGIC_VECTOR(15 downto 0);  -- 存储去抖后的按键状态
    signal key_pressed_stable : STD_LOGIC_VECTOR(15 downto 0);  -- 最终稳定的按键状态
	 
    -- 时钟分频计数器
    signal cnt : integer;
	 signal cnt2 : integer;
	 --分频信号
	 signal clk_1ms : STD_LOGIC := '0'; 
	 signal clk_2 : STD_LOGIC := '0'; ---只当作蜂鸣器脉冲

    -- 随机数生成
    signal random_count : integer := 0;

    -- 计时器
    signal timer : integer range 0 to 9999 := 0;
    signal timer_enable : STD_LOGIC := '0';

    -- 蜂鸣器频率
    signal buzzer_signal : STD_LOGIC := '0';

	 -- 数码管计数
	 signal cnt1:integer range 0 to 5:=0; --计数
	 
	 -- 数码管段选编码（低电平有效）
    function get_digit_segment(digit: integer) return STD_LOGIC_VECTOR is
    begin
        case digit is
            when 0 => return "00000011";  -- 数字 0 对应的段选信号
            when 1 => return "10011111";  -- 数字 1 对应的段选信号
            when 2 => return "00100101";  -- 数字 2 对应的段选信号
            when 3 => return "00001101";  -- 数字 3 对应的段选信号
            when 4 => return "10011001";  -- 数字 4 对应的段选信号
            when 5 => return "01001001";  -- 数字 5 对应的段选信号
            when 6 => return "01000001";  -- 数字 6 对应的段选信号
            when 7 => return "00011111";  -- 数字 7 对应的段选信号
            when 8 => return "00000001";  -- 数字 8 对应的段选信号
            when 9 => return "00001001";  -- 数字 9 对应的段选信号
            when others => return "00000011"; -- 默认返回0
        end case;
    end function;
	 
begin
    -- 时钟分频：用于生成1ms时钟
    process(clk)
    begin
        if clk'event and clk ='1' then
            cnt<=cnt+1;
        end if;

        if cnt = 24000 then
            cnt<=0;
        end if;
        if cnt < 12000 then
            clk_1ms<='1';
        else if cnt > 12000 then
            clk_1ms<='0';
        end if;
    end if;
    end process;

    -- 主状态机
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= READY;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, reset, start, stop, timer, random_count)
    begin
        case current_state is
            when READY =>
                -- 初始化显示
                if start = '1' then
                    next_state <= RANDOM_DELAY;
                else
                    next_state <= READY;
                end if;

            when RANDOM_DELAY =>
                -- 进入犯规状态
                if stop = '1' then
                    next_state <= VIOLATION;   
					 -- 延时2~6秒
                elsif random_count = 4 then
                    next_state <= TIMING;
                else
                    next_state <= RANDOM_DELAY;
                end if;

            when TIMING =>
                -- 开始计时
                if stop = '1' then
                    next_state <= DONE;
                elsif timer = 9999 then
                    next_state <= DONE;
                else
                    next_state <= TIMING;
                end if;

            when DONE =>
                -- 计时完成
                if reset = '1' then
                    next_state <= READY;
                else
                    next_state <= DONE;
                end if;

            when VIOLATION =>
                -- 犯规
                if reset = '1' then
                    next_state <= READY;
                else
                    next_state <= VIOLATION;
                end if;

            when others =>
                next_state <= READY;
        end case;
    end process;

	 -- random_count随机数的递减
	 process(clk_1ms)
    begin
        if rising_edge(clk_1ms) and current_state = RANDOM_DELAY then
            if random_count < 4 then
                random_count <= random_count + 1;
            end if;
        end if;
    end process;

	 --计时器状态控制
	 process(current_state)
    begin
        case current_state is
            when TIMING =>
                timer_enable <= '1';
            when others =>
                timer_enable <= '0';
        end case;
    end process;
	 
    -- 计时器
    process(clk_1ms)
    begin
        if rising_edge(clk_1ms) then
            if timer_enable = '1' then
                if timer < 9999 then
                    timer <= timer + 1;
                else
                    timer <= 9999;
                end if;
            end if;
        end if;
    end process;
	 
	 
    -- 数码管扫描位计数器
	 process(clk)
	 begin
	     if rising_edge(clk) then
		      if cnt1 = 5 then 
				   cnt1 <= 0;
				else
               cnt1 <= cnt1+1;
			   end if;
		  end if;
	 end process;	  
		  
	 ---- 更新数码管显示
	 process(current_state, timer)
        variable num : integer := timer;  -- 假设timer是要显示的计数器值
    begin
        if (current_state = TIMING) or (current_state = DONE)then
		      case cnt1 is
            -- 显示六位数码管，数字不足6位时填充前导零
              -- 选择显示的数码管（全部打开显示）
            when 0 =>seg <= get_digit_segment(num / 100000 mod 10); dig <= "011111";  -- 第一位（最高位）			         
            when 1 =>seg <= get_digit_segment(num / 10000 mod 10);  dig <= "101111";  -- 第二位
            when 2 =>seg <= get_digit_segment(num / 1000 mod 10);   dig <= "110111";  -- 第三位
            when 3 =>seg <= get_digit_segment(num / 100 mod 10);    dig <= "111011";  -- 第四位
            when 4 =>seg <= get_digit_segment(num / 10 mod 10);     dig <= "111101";  -- 第五位
            when 5 =>seg <= get_digit_segment(num mod 10);          dig <= "111110";  -- 第六位
				end case;
        else
            dig <="111111";
				
        end if;
    end process;
	 
	 
	 -- LED指示灯控制
    process(current_state, clk_1ms)
    begin
        case current_state is
            when READY =>
                led <= '1';  -- 准备时点亮指示灯
            when RANDOM_DELAY =>
                led <= '0';  -- 随机延时时关闭指示灯
            when TIMING =>
                led <= '1';  -- 开始计时时点亮指示灯
            when DONE =>
                led <= '0';  -- 计时完成时指示灯关闭
            when VIOLATION =>
                led <= clk_1ms;  -- 犯规时指示灯闪烁
            when others =>
                led <= '0';  -- 其他状态时关闭指示灯
        end case;
    end process;
	 
	 --LED矩阵行选
	 process(clk)
	 begin
	 if rising_edge(clk) then
	 case led_row is
	 			 when "0111111111111111" => led_row <= "1011111111111111";--让每一行都有效就是在较短时间内进行移位
				 when "1011111111111111" => led_row <= "1101111111111111";
				 when "1101111111111111" => led_row <= "1110111111111111";
				 when "1110111111111111" => led_row <= "1111011111111111";
				 when "1111011111111111" => led_row <= "1111101111111111";
			 	 when "1111101111111111" => led_row <= "1111110111111111";
				 when "1111110111111111" => led_row <= "1111111011111111";
				 when "1111111011111111" => led_row <= "1111111101111111";
				 when "1111111101111111" => led_row <= "1111111110111111";
				 when "1111111110111111" => led_row <= "1111111111011111";
				 when "1111111111011111" => led_row <= "1111111111101111";
				 when "1111111111101111" => led_row <= "1111111111110111";
				 when "1111111111110111" => led_row <= "1111111111111011";
				 when "1111111111111011" => led_row <= "1111111111111101";
				 when "1111111111111101" => led_row <= "1111111111111110";
				 when "1111111111111110" => led_row <= "0111111111111111";
				 when  others  => led_row <= "0111111111111111";
			 end case;
		 end if;
	 end process;

	  --
	 process (led_row,current_state)
	 begin
	  Case current_state is 				
        when READY =>
        case led_row is
            when"0111111111111111"=>led_col<="1111111010111111";--准
            when"1011111111111111"=>led_col<="1011111011011111";
            when"1101111111111111"=>led_col<="1101111011011111";
            when"1110111111111111"=>led_col<="1101110000000001";
            when"1111011111111111"=>led_col<="1111110111011111";
            when"1111101111111111"=>led_col<="1110100111011111";
            when"1111110111111111"=>led_col<="1110010000000011";
            when"1111111011111111"=>led_col<="1110110111011111";
            when"1111111101111111"=>led_col<="1101110111011111";
            when"1111111110111111"=>led_col<="1101110000000011";
            when"1111111111011111"=>led_col<="0001110111011111";
            when"1111111111101111"=>led_col<="1101110111011111";
            when"1111111111110111"=>led_col<="1101110111011111";
            when"1111111111111011"=>led_col<="1101110000000001";
            when"1111111111111101"=>led_col<="1101110111111111";
            when"1111111111111110"=>led_col<="1111110111111111";
            when  others  => led_col <= "0111111111111111";
        end case;
		  
		  when RANDOM_DELAY =>
        case led_row is
            when"0111111111111111"=>led_col<="1110111111011111";--始
            when"1011111111111111"=>led_col<="1110111111011111";
            when"1101111111111111"=>led_col<="1110111111011111";
            when"1110111111111111"=>led_col<="1110111110111111";
            when"1111011111111111"=>led_col<="0000001110110111";
            when"1111101111111111"=>led_col<="1101101101111011";
            when"1111110111111111"=>led_col<="1101101000000001";
            when"1111111011111111"=>led_col<="1101101101111101";
            when"1111111101111111"=>led_col<="1101101111111111";
            when"1111111110111111"=>led_col<="1011011100000011";
            when"1111111111011111"=>led_col<="1101011101111011";
            when"1111111111101111"=>led_col<="1110111101111011";
            when"1111111111110111"=>led_col<="1101011101111011";
            when"1111111111111011"=>led_col<="1011101101111011";
            when"1111111111111101"=>led_col<="0111111100000011";
            when"1111111111111110"=>led_col<="1111111101111011";
            when  others  => led_col <= "0111111111111111";
        end case;
		  
		  when TIMING =>
        case led_row is
            when"0111111111111111"=>led_col<="1111111110111111";--计
            when"1011111111111111"=>led_col<="1101111110111111";
            when"1101111111111111"=>led_col<="1110111110111111";
            when"1110111111111111"=>led_col<="1110111110111111";
            when"1111011111111111"=>led_col<="1111111110111111";
            when"1111101111111111"=>led_col<="1111111110111111";
            when"1111110111111111"=>led_col<="0000100000000001";
            when"1111111011111111"=>led_col<="1110111110111111";
            when"1111111101111111"=>led_col<="1110111110111111";
            when"1111111110111111"=>led_col<="1110111110111111";
            when"1111111111011111"=>led_col<="1110111110111111";
            when"1111111111101111"=>led_col<="1110111110111111";
            when"1111111111110111"=>led_col<="1110101110111111";
            when"1111111111111011"=>led_col<="1110011110111111";
            when"1111111111111101"=>led_col<="1110111110111111";
            when"1111111111111110"=>led_col<="1111111110111111";
            when  others  => led_col <= "0111111111111111";
        end case;
		  
		  when DONE =>
        case led_row is
            when"0111111111111111"=>led_col<="1111110111111111";--完
            when"1011111111111111"=>led_col<="1111111011111111";
            when"1101111111111111"=>led_col<="1000000000000001";
            when"1110111111111111"=>led_col<="1011111111111101";
            when"1111011111111111"=>led_col<="0111111111111011";
            when"1111101111111111"=>led_col<="1110000000001111";
            when"1111110111111111"=>led_col<="1111111111111111";
            when"1111111011111111"=>led_col<="1111111111111111";
            when"1111111101111111"=>led_col<="1000000000000011";
            when"1111111110111111"=>led_col<="1111101110111111";
            when"1111111111011111"=>led_col<="1111101110111111";
            when"1111111111101111"=>led_col<="1111101110111111";
            when"1111111111110111"=>led_col<="1111011110111011";
            when"1111111111111011"=>led_col<="1111011110111011";
            when"1111111111111101"=>led_col<="1110111110111011";
            when"1111111111111110"=>led_col<="1001111111000011";
            when  others  => led_col <= "0111111111111111";
        end case;
		  
		  when VIOLATION =>
        case led_row is
            when"0111111111111111"=>led_col<="1110111111111111";--规
            when"1011111111111111"=>led_col<="1110111000000011";
            when"1101111111111111"=>led_col<="1110111011111011";
            when"1110111111111111"=>led_col<="1000001011111011";
            when"1111011111111111"=>led_col<="1110111011011011";
            when"1111101111111111"=>led_col<="1110111011011011";
            when"1111110111111111"=>led_col<="1110111011011011";
            when"1111111011111111"=>led_col<="0000000011011011";
            when"1111111101111111"=>led_col<="1110111011011011";
            when"1111111110111111"=>led_col<="1110111010101011";
            when"1111111111011111"=>led_col<="1110111110101111";
            when"1111111111101111"=>led_col<="1101011101101111";
            when"1111111111110111"=>led_col<="1101101101101111";
            when"1111111111111011"=>led_col<="1011101011101101";
            when"1111111111111101"=>led_col<="0111110111101101";
            when"1111111111111110"=>led_col<="1111101111110001";
            when  others  => led_col <= "0111111111111111";
        end case;		
       
        when others  => led_col <= "0111111111111111";
 
		
	  end Case;
    end process;

	 -- 时钟分频：用于给蜂鸣器输出1.2khz
    process(clk)
    begin
        if clk'event and clk ='1' then
            cnt2<=cnt2+1;
        end if;

        if cnt2 = 10000 then
            cnt2<=0;
        end if;
        if cnt2 < 5000 then
            clk_2<='1';
        else if cnt2 > 5000 then
            clk_2<='0';
        end if;
    end if;
    end process;
	 
	 -- 蜂鸣器控制
    process(current_state, clk_1ms, clk_2)
    begin
        case current_state is
            when READY =>
                buzzer_signal <= '0';  -- 准备状态时关闭蜂鸣器
            when RANDOM_DELAY =>
                buzzer_signal <= '0';  -- 随机延迟时开启蜂鸣器
            when TIMING =>
                buzzer_signal <= clk_2;  -- 开始计时时蜂鸣器灭
            when DONE =>
                buzzer_signal <= '0';  -- 计时结束时蜂鸣器灭
            when VIOLATION =>
                buzzer_signal <= clk_1ms;  -- 犯规时闪烁蜂鸣器
            when others =>
                buzzer_signal <= '0';  -- 其他状态时关闭蜂鸣器
        end case;
        buzzer <= buzzer_signal;
    end process;

end Behavioral;
