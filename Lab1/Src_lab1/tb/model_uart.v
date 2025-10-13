`timescale 1ns / 1ps

module model_uart(/*AUTOARG*/
   // Outputs
   TX,
   // Inputs
   RX
   );

   output TX;
   input  RX;

   parameter baud    = 115200;
   parameter bittime = 1000000000/baud;
   parameter name    = "UART0";
   
   reg [7:0] rxData;
   event     evBit;
   event     evByte;
   event     evTxBit;
   event     evTxByte;
   reg       TX;
   
   // our additions!
   reg [7:0] rxBuffer [0:4];
   integer rxBufferCount = 0;
   integer i;
   reg [8*5-1:0] myString;

   initial
     begin
        TX = 1'b1;
        rxBufferCount = 0;
     end
   
   always @ (negedge RX)
     begin
        rxData[7:0] = 8'h0;
        #(0.5*bittime);
        repeat (8)
          begin
             #bittime ->evBit;
             //rxData[7:0] = {rxData[6:0],RX};
             rxData[7:0] = {RX,rxData[7:1]};
          end
        ->evByte;
        // our modifications!
        // $display ("%d %s Received byte %02x (%s)", $stime, name, rxData, rxData);
        if (rxData == 8'h72) begin // 'r' because that's what we rx???
          // $display("foo");
          myString = "";
          for (i = 0; i < rxBufferCount; i = i + 1)
            myString = {myString, rxBuffer[i]};
          $display ("%d %s Received string %s", $stime, name, myString);
          rxBufferCount = 0;
        end
        else begin
          rxBuffer[rxBufferCount] = rxData;
          rxBufferCount = rxBufferCount + 1;
        end
     end

   task tskRxData;
      output [7:0] data;
      begin
         @(evByte);
         data = rxData;
      end
   endtask // for
      
   task tskTxData;
      input [7:0] data;
      reg [9:0]   tmp;
      integer     i;
      begin
         tmp = {1'b1, data[7:0], 1'b0};
         for (i=0;i<10;i=i+1)
           begin
              TX = tmp[i];
              #bittime;
              ->evTxBit;
           end
         ->evTxByte;
      end
   endtask // tskTxData
   
endmodule // model_uart
