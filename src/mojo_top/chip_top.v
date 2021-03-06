module chip_top (
	input clk_i,
	input rst_i,
	input rx_new_i,
	input [7:0] rx_data_i,
	input tx_busy_i,
	output tx_new_o,
	output [7:0] tx_data_o,
	output enabled_o,
	output nonce_ready_o
);

wire [255:0] nonce_w;
wire [1023:0] key_constant_o_w;
wire [191:0] tweak_select_o_w;
wire [63:0] tweak_word_select_o_w;
wire [4:0] subkey_w;
wire [1:0] tweak_word_select_w;
wire [63:0] tweak_add_type_select_o_w;
wire [15:0] permute_logic_y0_o_w;
wire [15:0] permute_logic_y1_o_w;
wire [15:0] or_w;
wire [15:0] output_register_write_w;
wire [15:0] y0_add_mode_select_o_w;
wire [15:0] word_to_bit_o_w;
wire [5:0] rotate_constant_w;
wire [2:0] d_w;
wire [2:0] j_w;
wire [6:0] round_w;
wire [3:0] word_w;
wire hash_mode_w;
wire y0_add_select_w;
wire word_counter_reset_w;
wire word_counter_plus_1_w;
wire word_counter_plus_2_w;
wire round_counter_increment_w;
wire round_counter_reset_w;
wire input_register_write_w;
wire output_register_write_enable_w;
wire key_register_write_w;
wire subkey_register_write_w;
wire x0_key_select_w;
wire [1:0] x1_tweak_subkey_select_w;
wire output_register_plaintext_select_w;
wire hash_mode_toggle_w;
wire [1:0] tweak_add_type_w;
wire hash_register_write_w;
wire [1023:0] hash_register_w;
wire nonce_ready;
wire nonce_receive;
wire reset_best_nonce;
wire [255:0] best_nonce;
wire [9:0] best_bits_off;

assign subkey_w = round_w % 4;
assign or_w = permute_logic_y0_o_w | permute_logic_y1_o_w;
assign d_w = round_w[6:4];
assign j_w = word_w[3:1];
assign nonce_ready_o = nonce_ready;

state_machine state_machine (
	.clk_i(clk_i),
	.rst_i(rst_i),
	.round_counter_i(round_w),
	.word_counter_i(word_w),
	.hash_mode_i(hash_mode_w),

	// Mealy Outputs
	.word_counter_reset_o(word_counter_reset_w),
	.word_counter_plus_1_o(word_counter_plus_1_w),
	.word_counter_plus_2_o(word_counter_plus_2_w),
	.round_counter_increment_o(round_counter_increment_w),
	.round_counter_reset_o(round_counter_reset_w),
	.hash_register_write_o(hash_register_write_w),

	// Moore Outputs
	.input_register_write_o(input_register_write_w),
	.output_register_write_o(output_register_write_enable_w),
	.key_register_write_o(key_register_write_w),
	.subkey_register_write_o(subkey_register_write_w),
	.x0_key_select_o(x0_key_select_w),
	.x1_tweak_subkey_select_o(x1_tweak_subkey_select_w),
	.output_register_plaintext_select_o(output_register_plaintext_select_w),
	.hash_mode_toggle_o(hash_mode_toggle_w),
	.y0_add_select_o(y0_add_select_w)
);

serial_interface serial_interface (
  .clk_i(clk_i),
	.rst_i(rst_i),
  .rx_new_i(rx_new_i),
  .rx_data_i(rx_data_i),
  .tx_busy_i(tx_busy_i),
  .nonce_ready_i(nonce_ready),
  .nonce_i(best_nonce),
	.nonce_bits_off_i(best_bits_off),
  .tx_new_o(tx_new_o),
  .tx_data_o(tx_data_o),
  .nonce_receive_o(nonce_receive),
  .chip_enabled_o(enabled_o),
	.reset_best_nonce_o(reset_best_nonce)
);

word_counter word_counter (
	.clk_i(clk_i),
	.word_counter_reset_i(word_counter_reset_w),
	.word_counter_plus_1_i(word_counter_plus_1_w),
	.word_counter_plus_2_i(word_counter_plus_2_w),
	.word_counter_o(word_w)
);

round_counter round_counter (
	.clk_i(clk_i),
	.increment_i(round_counter_increment_w),
	.reset_i(round_counter_reset_w),
	.round_counter_o(round_w)
);

hash_mode_register hash_mode_register (
	.clk_i(clk_i),
	.toggle_i(hash_mode_toggle_w),
	.hash_mode_o(hash_mode_w)
);

output_register_write_enable output_register_write_enable (
	.write_bits_i(y0_add_mode_select_o_w),
	.write_enable_i(output_register_write_enable_w),
	.write_bits_o(output_register_write_w)
);

nonce_register_top nonce_register_top (
	.clk_i(clk_i),
	.receive_new_nonce_i(nonce_receive),
	.increment_i(hash_register_write_w),
	.rx_new_i(rx_new_i),
	.rx_data_i(rx_data_i),
	.ready_o(nonce_ready),
	.nonce_o(nonce_w)
);

key_constant key_constant (
	.key_o(key_constant_o_w)
);

tweak_select tweak_select (
	.mode_i(hash_mode_w),
	.tweak_o(tweak_select_o_w)
);

tweak_word_select tweak_word_select (
	.select_i(tweak_word_select_w),
	.tweak_i(tweak_select_o_w),
	.tweak_word_o(tweak_word_select_o_w)
);

tweak_add_type_select_logic tweak_add_type_select_logic (
	.word_i(word_w),
	.tweak_add_type_o(tweak_add_type_w)
);

tweak_add_type_select tweak_add_type_select (
	.type_i(tweak_add_type_w),
	.subkey_select_i(subkey_w),
	.tweak_word_i(tweak_word_select_o_w),
	.tweak_add_word_o(tweak_add_type_select_o_w),
	.tweak_word_select_o(tweak_word_select_w)
);

permute_logic_y0 permute_logic_y0 (
	.word_i(word_w),
	.word_select_o(permute_logic_y0_o_w)
);

permute_logic_y1 permute_logic_y1 (
	.word_i(word_w),
	.word_select_o(permute_logic_y1_o_w)
);

y0_add_mode_select y0_add_mode_select (
	.mode_i(y0_add_select_w),
	.y0_i(or_w),
	.add_i(word_to_bit_o_w),
	.selected_o(y0_add_mode_select_o_w)
);

word_to_bit word_to_bit (
	.word_i(word_w),
	.bits_o(word_to_bit_o_w)
);

rotator_constant rotator_constant (
	.d_i(d_w),
	.j_i(j_w),
	.rotate_bits_o(rotate_constant_w)
);

core core0 (
	.clk_i(clk_i),
	.rst_i(rst_i),
	.input_register_write_i(input_register_write_w),
	.word_i(word_w),
	.x0_key_select_i(x0_key_select_w),
	.x1_tweak_subkey_select_i(x1_tweak_subkey_select_w),
	.tweak_word_i(tweak_add_type_select_o_w),
	.rotate_constant_i(rotate_constant_w),
	.Y1_select_i(permute_logic_y1_o_w),
	.output_register_write_i(output_register_write_w),
	.key_register_write_i(key_register_write_w),
	.hash_mode_i(hash_mode_w),
	.subkey_write_i(subkey_register_write_w),
	.output_register_plaintext_select_i(output_register_plaintext_select_w),
	.nonce_i(nonce_w),
	.key_constant_i(key_constant_o_w),
	.subkey_i(subkey_w),
	.hash_register_write_i(hash_register_write_w),
	.best_nonce_o(best_nonce),
	.best_bits_off_o(best_bits_off),
	.reset_best_nonce_i(reset_best_nonce)
);

endmodule
