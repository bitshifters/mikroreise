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

for i=1,tot do
    a=3.1*pi/500
    b=2.8*pi/500
    c=1
    xt=a*i
    yt=b*(i+t)
    -- x=100*cos(xt)*cos(xt*cos(xt))
    x=152*cos(xt)*cos(xt*2)
    -- y=32*sin(yt*2)*cos(yt*sin(yt*3))
    y=120*sin(yt)*sin(yt*2)
    writeLong(file1,math.modf(cx+x))
    writeLong(file2,scr_base1+math.modf(cy+y)*320)    -- mode stride.
    writeLong(file3,scr_base2+math.modf(cy+y)*320)    -- mode stride.

    if (register==0) then
        file4:write("ldmia r9!, {r0-r7}\n")
    end

    x_values[register+1]=math.modf(cx+x)

    register=register + 1

    if (register==8) then
        for i=1,8 do
            -- file4:write(string.format("add r14, r12, r%d\n", i-1))
            file4:write(string.format("strb r10, [r%d, #%d]\n", i-1, x_values[i]))
        end

        for i=1,8 do
            -- file4:write(string.format("sub r14, r11, r%d\n", i-1))
            file4:write(string.format("sub r14, r11, r%d\n", i-1))
            file4:write(string.format("strb r8, [r14, #%d]\n", x_values[i]))
        end
        
        register=0
    end

end

file1:close()
file2:close()
file3:close()
file4:close()
