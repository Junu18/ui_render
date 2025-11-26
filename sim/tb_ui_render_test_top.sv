// tb_ui_render_test_top.sv
// ui_render_test_top 테스트벤치
// 검증 항목:
//   1. 클럭 생성 및 리셋
//   2. 버튼 입력 → pos_valid + active_player 생성
//   3. 플레이어 이동 애니메이션 (MOVING → JUMPING)
//   4. turn_done 신호 확인
//   5. VGA 신호 타이밍

`timescale 1ns / 1ps

module tb_ui_render_test_top;

    // ========================================
    // DUT 신호
    // ========================================
    logic       clk_100mhz;
    logic       btn_reset, btnL, btnU, btnR;
    logic [3:0] vga_r, vga_g, vga_b;
    logic       vga_hsync, vga_vsync;
    logic [3:0] led;

    // ========================================
    // 클럭 생성 (100MHz)
    // ========================================
    initial begin
        clk_100mhz = 0;
        forever #5 clk_100mhz = ~clk_100mhz;  // 10ns period = 100MHz
    end

    // ========================================
    // DUT 인스턴스
    // ========================================
    ui_render_test_top dut (
        .clk_100mhz(clk_100mhz),
        .btn_reset(btn_reset),
        .btnL(btnL),
        .btnU(btnU),
        .btnR(btnR),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .led(led)
    );

    // ========================================
    // 내부 신호 모니터링 (Hierarchical reference)
    // ========================================
    wire [9:0] player1_pos_x = dut.player1_pos_x_sim;
    wire       pos_valid = dut.pos_valid_sim;
    wire       active_player = dut.active_player_sim;
    wire       turn_done = dut.turn_done;
    wire [9:0] player1_x = dut.ui.ctrl.player1_x;
    wire [9:0] player1_y = dut.ui.ctrl.player1_y;
    wire [2:0] fsm_state = dut.ui.ctrl.state;
    wire [4:0] counter = dut.ui.ctrl.counter;
    wire [9:0] jump_offset = dut.ui.ctrl.jump_offset;
    wire [9:0] current_y = dut.ui.ctrl.current_y;

    // FSM 상태 디코딩
    string state_name;
    always_comb begin
        case (fsm_state)
            3'b000: state_name = "IDLE";
            3'b001: state_name = "MOVING";
            3'b010: state_name = "JUMPING";
            3'b011: state_name = "FLAG_SLIDING";
            default: state_name = "UNKNOWN";
        endcase
    end

    // ========================================
    // 테스트 시나리오
    // ========================================
    initial begin
        $display("========================================");
        $display("UI Render Test Top Testbench");
        $display("========================================");

        // 초기화
        btn_reset = 0;
        btnL = 0;
        btnU = 0;
        btnR = 0;

        // 1. 리셋
        $display("\n[%0t] Test 1: Reset", $time);
        btn_reset = 1;
        repeat(10) @(posedge clk_100mhz);
        btn_reset = 0;
        repeat(10) @(posedge clk_100mhz);

        check_player_position(20, 124, "After reset");

        // 2. BTNL 테스트 (1칸 이동, 60px)
        $display("\n[%0t] Test 2: BTNL - Move 1 tile (60px)", $time);
        press_button("BTNL");
        wait_for_turn_done("BTNL");
        check_player_position(80, 124, "After 1 tile move");

        // 3. BTNU 테스트 (2칸 이동, 120px)
        $display("\n[%0t] Test 3: BTNU - Move 2 tiles (120px)", $time);
        press_button("BTNU");
        wait_for_turn_done("BTNU");
        check_player_position(200, 124, "After 2 tiles move");

        // 4. BTNR 테스트 (3칸 이동, 180px)
        $display("\n[%0t] Test 4: BTNR - Move 3 tiles (180px)", $time);
        press_button("BTNR");
        wait_for_turn_done("BTNR");
        check_player_position(380, 124, "After 3 tiles move");

        // 5. 깃발까지 이동 (x=620)
        $display("\n[%0t] Test 5: Move to flag (x=620)", $time);
        // 380 → 620 = 240px = 4칸
        press_button("BTNL");  // +60 → 440
        wait_for_turn_done("BTNL");
        press_button("BTNU");  // +120 → 560
        wait_for_turn_done("BTNU");
        press_button("BTNL");  // +60 → 620
        wait_for_turn_done("BTNL (Flag)");
        check_player_position(620, 124, "At flag");

        // 6. VGA 타이밍 체크
        $display("\n[%0t] Test 6: VGA Timing Check", $time);
        check_vga_timing();

        // 7. pos_valid 펄스 폭 확인
        $display("\n[%0t] Test 7: pos_valid Pulse Width", $time);
        check_pos_valid_pulse();

        $display("\n========================================");
        $display("All tests completed!");
        $display("========================================");

        repeat(100) @(posedge clk_100mhz);
        $finish;
    end

    // ========================================
    // 헬퍼 태스크
    // ========================================

    // 버튼 누르기 (디바운싱 고려)
    task automatic press_button(input string btn_name);
        begin
            $display("  [%0t] Pressing %s...", $time, btn_name);
            case (btn_name)
                "BTNL": btnL = 1;
                "BTNU": btnU = 1;
                "BTNR": btnR = 1;
                "BTNC": btnC = 1;
                "BTND": btnD = 1;
            endcase

            // 버튼 홀드 (디바운싱 시간보다 길게, 1ms = 100,000 cycles @ 100MHz)
            // 시뮬레이션에서는 짧게 (100 cycles)
            repeat(100) @(posedge clk_100mhz);

            case (btn_name)
                "BTNL": btnL = 0;
                "BTNU": btnU = 0;
                "BTNR": btnR = 0;
                "BTNC": btnC = 0;
                "BTND": btnD = 0;
            endcase

            repeat(10) @(posedge clk_100mhz);
        end
    endtask

    // turn_done 대기
    task wait_for_turn_done(input string context);
        begin
            int timeout_counter = 0;
            int max_timeout = 100000;  // 최대 대기 시간

            $display("  [%0t] Waiting for turn_done (%s)...", $time, msg);

            // turn_done 펄스 대기
            while (!turn_done && timeout_counter < max_timeout) begin
                @(posedge clk_100mhz);
                timeout_counter++;
            end

            if (turn_done) begin
                $display("  [%0t] ✓ turn_done received (after %0d cycles)", $time, timeout_counter);
            end else begin
                $display("  [%0t] ✗ ERROR: turn_done timeout!", $time);
            end

            // turn_done 펄스가 1 cycle인지 확인
            @(posedge clk_100mhz);
            if (turn_done) begin
                $display("  [%0t] ✗ ERROR: turn_done should be 1 cycle pulse!", $time);
            end
        end
    endtask

    // 플레이어 위치 확인
    task check_player_position(input int expected_x, input int expected_y, input string context);
        begin
            if (player1_x == expected_x && player1_y == expected_y) begin
                $display("  [%0t] ✓ %s: Position correct (x=%0d, y=%0d)",
                         $time, msg, player1_x, player1_y);
            end else begin
                $display("  [%0t] ✗ %s: Position mismatch! Expected (x=%0d, y=%0d), Got (x=%0d, y=%0d)",
                         $time, msg, expected_x, expected_y, player1_x, player1_y);
            end
        end
    endtask

    // VGA 타이밍 체크 (1 frame 확인)
    task automatic check_vga_timing();
        int hsync_count;
        int vsync_count;
        begin
            int hsync_count = 0;
            int vsync_count = 0;

            // Vsync 펄스 2개 대기 (1 frame)
            while (vsync_count < 2) begin
                @(posedge clk_100mhz);
                if (vga_vsync) vsync_count++;
            end

            $display("  [%0t] ✓ VGA frame detected", $time);
        end
    endtask

    // pos_valid 펄스 폭 확인
    task automatic check_pos_valid_pulse();
        int pulse_width;
        begin
            int pulse_width = 0;

            press_button("BTNL");

            // pos_valid rising edge 대기
            @(posedge clk_100mhz);
            while (!pos_valid) @(posedge clk_100mhz);

            // 펄스 폭 측정
            while (pos_valid) begin
                pulse_width++;
                @(posedge clk_100mhz);
            end

            if (pulse_width == 1) begin
                $display("  [%0t] ✓ pos_valid pulse width = 1 cycle", $time);
            end else begin
                $display("  [%0t] ✗ ERROR: pos_valid pulse width = %0d cycles (expected 1)",
                         $time, pulse_width);
            end
        end
    endtask

    // ========================================
    // 연속 모니터링
    // ========================================

    // FSM 상태 변화 모니터
    always @(posedge clk_100mhz) begin
        if (fsm_state != $past(fsm_state)) begin
            $display("  [%0t] FSM State: %s → %s",
                     $time, $past(state_name), state_name);
        end
    end

    // JUMPING 상태 중 상세 모니터링
    always @(posedge clk_100mhz) begin
        if (fsm_state == 3'b010) begin  // JUMPING
            $display("  [%0t] JUMPING: counter=%0d, jump_offset=%0d, current_y=%0d, player1_y=%0d",
                     $time, counter, jump_offset, current_y, player1_y);
        end
    end

    // pos_valid 펄스 감지
    always @(posedge clk_100mhz) begin
        if (pos_valid && !$past(pos_valid)) begin
            $display("  [%0t] pos_valid pulse detected (active_player=%0d, pos_x=%0d)",
                     $time, active_player, player1_pos_x);
        end
    end

    // turn_done 펄스 감지
    always @(posedge clk_100mhz) begin
        if (turn_done && !$past(turn_done)) begin
            $display("  [%0t] turn_done pulse detected", $time);
        end
    end

    // ========================================
    // 파형 덤프 (선택 사항)
    // ========================================
    initial begin
        $dumpfile("tb_ui_render_test_top.vcd");
        $dumpvars(0, tb_ui_render_test_top);
    end

    // ========================================
    // 타임아웃 (안전장치)
    // ========================================
    initial begin
        #100ms;  // 100ms 타임아웃
        $display("\n[%0t] ✗ ERROR: Simulation timeout!", $time);
        $finish;
    end

endmodule
