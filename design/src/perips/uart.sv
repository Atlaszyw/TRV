module uart #(

) (
  input clk_i,
  input rst_ni,

  input        we_i,
  input        req_i,
  input [31:0] addr_i,
  input [31:0] data_i,

  output logic ready_o,

  output logic [31:0] data_o,
  output logic        tx_pin,
  input               rx_pin
);


  // -------------------------------------------reg-----------------------------------------

  // 50MHz                  115200bps
  localparam BAUD_115200 = 32'h1B8;

  // addr: 0x00
  // rw. bit[0]: tx enable, 1 = enable, 0 = disable
  // rw. bit[1]: rx enable, 1 = enable, 0 = disable

  logic [1:0] uart_ctrl;
  always_ff @(posedge clk_i) begin : uart_ctrl_reg
    if (~rst_ni) uart_ctrl <= '0;
    else if (req_i && we_i && addr_i[0 +: 8] == 8'h00) uart_ctrl <= data_i[0 +: 2];
  end : uart_ctrl_reg
  // addr: 0x04
  // ro. bit[0]: tx busy, 1 = busy, 0 = idle
  // rw. bit[1]: rx over, 1 = over, 0 = receiving
  // must check this bit before tx data
  //   logic [1:0] uart_status;
  logic rx_over, tx_busy;

  // addr: 0x08
  // rw. clk_i div
  logic [31:0] uart_baud;
  always_ff @(posedge clk_i) begin : uart_baud_reg
    if (~rst_ni) uart_baud <= 32'h1B8;
    else if (req_i && we_i && addr_i[0 +: 8] == 8'h08) uart_baud <= data_i;
  end : uart_baud_reg

  // --------------------------------TX-----------------------------------------
  logic [7:0] rom0[10] = '{8'h32, 8'h30, 8'h32, 8'h33, 8'h32, 8'h31, 8'h31, 8'h30, 8'h36, 8'h31};

  logic [7:0] rom1[10] = '{8'h32, 8'h30, 8'h32, 8'h33, 8'h32, 8'h31, 8'h31, 8'h30, 8'h36, 8'h31};

  typedef enum logic [1:0] {
    TX_IDLE,
    TX_EMITTING,
    TX_STOP,
    TX_DONE
  } tx_state_e;
  tx_state_e tx_s_d, tx_s_q;

  typedef enum logic [2:0] {
    NUM_IDLE,
    NUM_WAITING,
    NUM_EMITTING,
    NUM_DONE
  } reginum_state_e;
  reginum_state_e regi_s_d, regi_s_q;

  logic [7:0] tx_data;  // 0x0c
  logic tx_data_valid;
  logic [3:0] tx_bit_cnt;
  logic [3:0] tx_num_cnt;
  logic [31:0] tx_cnt;

  logic tx_done;
  assign tx_done = tx_s_q == TX_DONE && tx_s_d == TX_IDLE;

  always_comb begin : ready_o_ctrl
    ready_o = '0;
    if (regi_s_q == NUM_DONE) ready_o = '1;
    else if (regi_s_q != NUM_EMITTING && tx_s_q == TX_DONE) ready_o = '1;
    else if (req_i & ~we_i) ready_o = '1;
    else if (req_i && we_i && (addr_i[0 +: 8] == 8'h00 || addr_i[0 +: 8] == 8'h04 || addr_i[0 +: 8] == 8'h08)) ready_o = '1;
  end : ready_o_ctrl

  // reginum state
  always_ff @(posedge clk_i) begin : reginum_d2q
    if (~rst_ni) regi_s_q <= NUM_IDLE;
    else regi_s_q <= regi_s_d;
  end : reginum_d2q

  always_comb begin : reginum_ns
    regi_s_d = regi_s_q;
    case (regi_s_q)
      NUM_IDLE:
      if (req_i && we_i && addr_i[0 +: 8] == 8'h14) begin
        if (tx_busy) regi_s_d = NUM_WAITING;
        else regi_s_d = NUM_EMITTING;
      end
      NUM_WAITING:  if (~tx_busy) regi_s_d = NUM_EMITTING;
      NUM_EMITTING: if (tx_num_cnt == 4'd9 && (tx_done)) regi_s_d = NUM_DONE;
      NUM_DONE:     regi_s_d = NUM_IDLE;
    endcase
  end : reginum_ns

  // tx state
  always_ff @(posedge clk_i) begin : tx_d2q
    if (~rst_ni) tx_s_q <= TX_IDLE;
    else tx_s_q <= tx_s_d;
  end : tx_d2q

  always_comb begin : tx_ns
    tx_s_d = tx_s_q;
    case (tx_s_q)
      TX_IDLE: begin
        if (~uart_ctrl[0]) tx_s_d = TX_IDLE;
        else if (tx_data_valid) tx_s_d = TX_EMITTING;
      end
      TX_EMITTING: begin
        if (tx_bit_cnt == 4'd8 && ~|tx_cnt) tx_s_d = TX_STOP;
      end
      TX_STOP: if (~|tx_cnt) tx_s_d = TX_DONE;
      TX_DONE: tx_s_d = TX_IDLE;
    endcase
  end : tx_ns

  always_ff @(posedge clk_i) begin : tx_num_cnt_ctrl
    if (~rst_ni || regi_s_q == NUM_IDLE) tx_num_cnt <= '0;
    else if (regi_s_q == NUM_EMITTING) begin
      if (tx_done) begin
        tx_num_cnt <= tx_num_cnt + 1'b1;
      end
    end
  end : tx_num_cnt_ctrl

  // tx
  always_ff @(posedge clk_i) begin : tx_data_reg
    if (~rst_ni || tx_done) begin
      tx_data       <= '0;
      tx_data_valid <= '0;
    end
    else if (regi_s_q == NUM_EMITTING) begin
      if (tx_s_q == TX_IDLE) begin
        tx_data       <= rom0[tx_num_cnt];
        tx_data_valid <= '1;
      end
      else if (tx_s_q == TX_IDLE && tx_s_d == TX_EMITTING) begin
        tx_data       <= tx_data;
        tx_data_valid <= '0;
      end
    end
    else if (regi_s_q == NUM_IDLE) begin
      if (req_i && we_i && addr_i[0 +: 8] == 8'h0c) begin
        tx_data       <= data_i;
        tx_data_valid <= '1;
      end
      else if (tx_s_q == TX_IDLE && tx_s_d == TX_EMITTING) begin
        tx_data       <= tx_data;
        tx_data_valid <= '0;
      end
    end
  end : tx_data_reg

  always_ff @(posedge clk_i) begin : tx_cnt_ctrl
    if (~rst_ni) tx_cnt <= BAUD_115200;
    else if (tx_s_q == TX_IDLE) tx_cnt <= uart_baud;
    else if (tx_s_q == TX_EMITTING || tx_s_q == TX_STOP) begin
      if (|tx_cnt) tx_cnt <= tx_cnt - 1'b1;
      else tx_cnt <= uart_baud;
    end
  end : tx_cnt_ctrl

  always_ff @(posedge clk_i) begin : tx_cnt_bit_ctrl
    if (~rst_ni) tx_bit_cnt <= 4'h0;
    else if (tx_s_q == TX_EMITTING && ~|tx_cnt && tx_bit_cnt < 4'd8) tx_bit_cnt <= tx_bit_cnt + 1'b1;
    else if (tx_s_q == TX_STOP || tx_s_q == TX_IDLE) tx_bit_cnt <= 4'h0;
  end : tx_cnt_bit_ctrl

  //       buffer
  logic [8:0] tx_buffer;
  always_ff @(posedge clk_i) begin : tx_buffer_ctrl
    if (~rst_ni) tx_buffer <= '1;
    else if (tx_s_q == TX_IDLE && tx_s_d == TX_EMITTING) tx_buffer <= {tx_data, 1'b0};
    else if (tx_s_q == TX_EMITTING && ~|tx_cnt) tx_buffer <= {1'b1, tx_buffer[8:1]};
    else if (tx_s_q == TX_STOP && tx_s_q == TX_IDLE) tx_buffer <= '1;
  end : tx_buffer_ctrl

  assign tx_pin  = tx_buffer[0];
  assign tx_busy = tx_s_q == TX_EMITTING || tx_s_q == TX_STOP || regi_s_q == NUM_EMITTING;

  // -----------------------------------------rx-------------------------------------------------

  logic negedge_detect;
  logic rx_pin_q0, rx_pin_q1;
  typedef enum logic [2:0] {
    RX_IDLE,
    RX_START_BIT,
    RX_DATA,
    RX_STOP
  } rx_state_e;
  rx_state_e rx_s_d, rx_s_q;
  logic [ 3:0] rx_bit_cnt;
  logic [31:0] rx_cnt;
  logic [ 7:0] rx_data;  // 0x10
  logic [ 2:0] rx_check_bit;
  logic [ 7:0] rx_buffer;
  logic rx_start_bit_check, rx_stop_bit_check, rx_data_check;

  logic rx_cnt_done;
  assign rx_cnt_done = ~|rx_cnt;

  always_ff @(posedge clk_i) begin : rx_pin_negedge_detect
    if (~rst_ni) begin
      rx_pin_q0 <= '0;
      rx_pin_q1 <= '0;
    end
    else begin
      rx_pin_q0 <= rx_pin;
      rx_pin_q1 <= rx_pin_q0;
    end
  end : rx_pin_negedge_detect

  assign negedge_detect = rx_pin_q1 & ~rx_pin_q0;

  always_ff @(posedge clk_i) begin : rx_d2q
    if (~rst_ni) rx_s_q <= RX_IDLE;
    else rx_s_q <= rx_s_d;
  end : rx_d2q

  always_comb begin : rx_ns
    rx_s_d = rx_s_q;
    case (rx_s_q)
      RX_IDLE:      if (negedge_detect) rx_s_d = RX_START_BIT;
      RX_START_BIT: if (rx_start_bit_check) rx_s_d = RX_DATA;
      RX_DATA:      if (rx_bit_cnt == 4'd0) rx_s_d = RX_STOP;
      RX_STOP:      if (rx_stop_bit_check) rx_s_d = RX_IDLE;
      default:      ;
    endcase
  end : rx_ns


  always_ff @(posedge clk_i) begin : rx_cnt_ctrl
    if (~rst_ni) rx_cnt <= BAUD_115200;
    else if (rx_s_q == RX_IDLE) begin
      if (rx_s_d == RX_START_BIT) rx_cnt <= uart_baud >> 1'b1;
    end
    else if (rx_s_q == RX_START_BIT) begin
      if (~rx_cnt_done) rx_cnt <= rx_cnt - 1'b1;
      else rx_cnt <= uart_baud;
    end
    else if (rx_s_q == RX_DATA || rx_s_q == RX_STOP) begin
      if (~rx_cnt_done) rx_cnt <= rx_cnt - 1'b1;
      else rx_cnt <= uart_baud;
    end
  end : rx_cnt_ctrl

  always_ff @(posedge clk_i) begin : rx_bit_cnt_ctrl
    if (~rst_ni) rx_bit_cnt <= 4'd8;
    else if (rx_s_q == RX_DATA) begin
      if (rx_data_check) rx_bit_cnt <= rx_bit_cnt - 1'b1;
    end
    else if (rx_s_q == RX_STOP || rx_s_q == RX_IDLE) begin
      rx_bit_cnt <= 4'd8;
    end
  end : rx_bit_cnt_ctrl

  always_ff @(posedge clk_i) begin : rx_check_bit_ctl
    if (~rst_ni) rx_check_bit <= '0;
    else rx_check_bit <= rx_check_bit << 1 | rx_pin;
  end : rx_check_bit_ctl

  assign rx_start_bit_check = rx_cnt_done && ~|rx_check_bit;
  assign rx_stop_bit_check  = rx_cnt_done && &rx_check_bit;
  assign rx_data_check      = rx_cnt_done && (&rx_check_bit | ~|rx_check_bit);

  always_ff @(posedge clk_i) begin : rx_data_pick
    if (~rst_ni) begin
      rx_buffer <= '0;
    end
    else if (rx_s_q == RX_DATA) begin
      if (rx_data_check) rx_buffer <= {rx_check_bit[0], rx_buffer[7:1]};
    end
  end : rx_data_pick

  always_ff @(posedge clk_i) begin : rx_data_reg_ctrl
    if (~rst_ni) begin
      rx_over <= '0;
      rx_data <= '0;
    end
    else if (rx_s_q == RX_STOP && rx_s_d == RX_IDLE) begin
      rx_data <= rx_buffer;
      rx_over <= '1;
    end
    else if (rx_s_q == RX_IDLE && rx_s_d == RX_START_BIT) begin
      rx_data <= '0;
      rx_over <= '0;
    end
    else if (req_i && we_i && addr_i[0 +: 8] == 8'h04) begin
      rx_over <= data_i[1];
    end
  end : rx_data_reg_ctrl

  always_comb begin : data_out_ctrl
    data_o = '0;
    if (req_i & ~we_i)
      case (addr_i[0 +: 8])
        8'h10:   data_o = rx_data;
        8'h04:   data_o = {rx_over, tx_busy};
        default: data_o = '0;
      endcase
  end : data_out_ctrl

endmodule
