if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# 1. Compile 
# Nên liệt kê theo thứ tự: module con trước, top module sau
vlog rtl/core/imem.v
vlog rtl/core/dmem.v
vlog rtl/core/regfile.v
vlog rtl/core/alu.v
vlog rtl/core/imm_gen.v
vlog rtl/core/alu_control.v
vlog rtl/core/control_unit.v
vlog rtl/core/pc.v
vlog rtl/core/multi_cycle_cpu.v

# 2. Compile file Testbench
vlog tb/tb_multi_cycle_cpu.v

# 3. Khởi chạy mô phỏng 
# (-voptargs="+acc" giúp ngăn ModelSim tối ưu hóa mất các tín hiệu, cần thiết để xem Wave)
vsim -voptargs="+acc" work.tb_multi_cycle_cpu

# 4. Cấu hình cửa sổ Waveform
# Hiển thị toàn bộ tín hiệu của testbench
add wave -position insertpoint sim:/tb_multi_cycle_cpu/*

