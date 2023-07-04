function writeShort(handle, short)
    local low_byte = short & 0xff
    local high_byte = (short >> 8) & 0xff
    handle:write(string.format("%c%c",low_byte,high_byte))
end

function writeLong(handle, long)
    local byte0 = long & 0xff
    local byte1 = (long >> 8) & 0xff
    local byte2 = (long >> 16) & 0xff
    local byte3 = (long >> 24) & 0xff
    handle:write(string.format("%c%c%c%c",byte0,byte1,byte2,byte3))
end

file1 = io.open("data/dots_x_table.bin", "wb")
file2 = io.open("data/dots_y_table_1.bin", "wb")
file3 = io.open("data/dots_y_table_2.bin", "wb")
file4 = io.open("src/dot_plot_generated.asm", "w")

t=0
sin=math.sin
cos=math.cos
pi=math.pi
num=1
tot=6504
cx=160
cy=128

register=0
x_values={}
scr_base1=0x01fd8000
scr_base2=0x01fec000

function map(value, in_low, in_high, out_low, out_high)
    if (value <= in_low) then
        return out_low
    end

    if (value >= in_high) then
        return out_high
    end

    local delta = (value-in_low) / (in_high-in_low)
    return out_low + delta * (out_high-out_low)
end

function radians(degrees)
    return degrees * 2 * pi / 360.0
end

screen_width=320
screen_height=256
width=256
height=240
stride=320
left_edge=(screen_width-width)/2
top_edge=(screen_height-height)/2

for i=1,tot do
    a = i*0.001

    -- Attempt 1.
    -- x = map(sin(a)*sin(a*0.8)*sin(a*-1.2), -1, 1, 0, width);
    -- y = map(sin(a*1.1+1.5)*sin(a*3.1)*sin(a*-2.5), -1, 1, 0, height);
  
    -- Attempt 2.
    -- x = map(sin(1.1*a)*100+10*cos(2.1*a), -110, 110, 0, width)
    -- y = map(cos(a)*100+10*sin(4.2*a), -110, 110, 0, height)

    angle = map(i, 0, tot, 0, pi);
 
    freqX = 13
    freqY = 11
    phi = 97

    modFreqX = 1
    modFreqY = 3

    modFreq2X = 11
    modFreq2Y = 17
    modFreq2Strength = 0.0

    -- an additional modulation of the osscillations
    fmx = sin(angle*modFreq2X) * modFreq2Strength + 1
    fmy = sin(angle*modFreq2Y) * modFreq2Strength + 1

    x = sin(angle * freqX * fmx + radians(phi)) * cos(angle * modFreqX)
    y = sin(angle * freqY * fmy) * cos(angle * modFreqY)

    x = map(x, -1, 1, 0, width)
    y = map(y, -1, 1, 0, height)

    xi = left_edge + math.modf(x)
    yi = top_edge + math.modf(y)

    writeLong(file1,xi)
    writeLong(file2,scr_base1+yi*stride)
    writeLong(file3,scr_base2+yi*stride)

    if (register==0) then
        file4:write("ldmia r9!, {r0-r7}\n")
    end

    x_values[register+1]=xi
    register=register + 1

    if (register==8) then
        for i=1,8 do
            -- file4:write(string.format("add r14, r12, r%d\n", i-1))
            file4:write(string.format("strb r10, [r%d, #%d]\n", i-1, x_values[i]))
        end

        for i=1,8 do
            -- file4:write(string.format("sub r14, r11, r%d\n", i-1))
            file4:write(string.format("sub r12, r11, r%d\n", i-1))
            file4:write(string.format("strb r8, [r12, #%d]\n", x_values[i]))
        end
        
        register=0
    end

end

file1:close()
file2:close()
file3:close()
file4:close()
