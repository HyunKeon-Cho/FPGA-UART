module FIFO
     #(parameter FDW = 32,  // fifof data width (data+rid+last)
                 FAW = 11,  // num of entries in 2 to the power FAW
                 FULN= 11)  // lookahead-full
(
       input   wire           rst // asynchronous reset (active high)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           aclk
     , output  wire           wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_din
     , input   wire           rd_rdy
     , output  wire           rd_vld
     , output  wire [FDW-1:0] rd_dout
     , output  wire           full
     , output  wire           empty
     , output  wire           fullN  // lookahead full
     , output  wire           emptyN // lookahead empty
     , output  reg  [FAW:0]   rd_cnt // num of elements in the FIFO to be read
     , output  wire [FAW:0]   wr_cnt // num of rooms in the FIFO to be written
);
   //---------------------------------------------------
   localparam FDT = 1<<FAW;
   //---------------------------------------------------
   reg  [FAW:0]   fifo_head; // where data to be read
   reg  [FAW:0]   fifo_tail; // where data to be written
   reg  [FAW:0]   next_tail;
   reg  [FAW:0]   next_head;
   wire [FAW-1:0] read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0]
                                              : fifo_head[FAW-1:0];

   //---------------------------------------------------
   // accept input
   // push data item into the entry pointed by fifo_tail
   //
   always @(posedge aclk or posedge rst) begin
      if (rst) begin
          fifo_tail <= 0;
          next_tail <= 1;
      end else if (clr) begin
          fifo_tail <= 0;
          next_tail <= 1;
      end else begin
          if (!full && wr_vld) begin
              fifo_tail <= next_tail;
              next_tail <= next_tail + 1;
          end 
      end
   end
   //---------------------------------------------------
   // provide output
   // pop data item from the entry pointed by fifo_head
   //
   always @(posedge aclk or posedge rst) begin
      if (rst) begin
          fifo_head <= 0;
          next_head <= 1;
      end else if (clr) begin
          fifo_head <= 0;
          next_head <= 1;
      end else begin
          if (!empty && rd_rdy) begin
              fifo_head <= next_head;
              next_head <= next_head + 1;
          end
      end
   end
   //---------------------------------------------------
   // how many items in the FIFO
   //
   assign  wr_cnt = FDT-rd_cnt;
   always @(posedge aclk or posedge rst) begin
      if (rst) begin
         rd_cnt <= 0;
      end else if (clr) begin
         rd_cnt <= 0;
      end else begin
         if (wr_vld&&!full&&!(rd_rdy&&!empty)) begin
             rd_cnt <= rd_cnt + 1;
         end else
         if (rd_rdy&&!empty&&!(wr_vld&&!full)) begin
             rd_cnt <= rd_cnt - 1;
         end
      end
   end
   
   //---------------------------------------------------
   assign rd_vld = ~empty;
   assign wr_rdy = ~full;
   assign empty  = (fifo_head == fifo_tail);
   assign full   = (rd_cnt>=FDT);
   //---------------------------------------------------
   assign fullN  = (rd_cnt>=(FDT-FULN));
   assign emptyN = (rd_cnt<=FULN);
   //---------------------------------------------------
 
   //---------------------------------------------------
   reg [FDW-1:0] Mem [0:FDT-1];
   assign rd_dout  = Mem[fifo_head[FAW-1:0]];
   always @(posedge aclk) begin
       if (!full && wr_vld) begin
           Mem[fifo_tail[FAW-1:0]] <= wr_din;
       end
   end
   //---------------------------------------------------
endmodule

//////////Edit code above!!/////////
////////////////////////////////////
