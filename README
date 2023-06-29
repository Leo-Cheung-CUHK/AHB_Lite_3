# AHB-Lite 3 Master-Slave Communication

This repository contains the SystemVerilog implementation of a master-slave communication using the AHB-Lite 3 protocol. The design includes a DMA memory on the slave side, a FIFO on the master side, and a FIFO reader helper that reads 32-bit data from the FIFO and splits them into 8-bit chunks.

![Code Structure](./Code%20Structure.png)

## SystemVerilog Modules

### `ahb3lite_top`

This module represents the top-level module of the AHB-Lite 3 communication design. It includes input and output ports for various signals such as clocks, resets, read requests, and system start. It also declares internal signals used for communication and synchronization between modules.

### `configure_FIFO` task

This task is responsible for configuring the FIFO module. It takes input parameters for the programmable empty and full thresholds and updates the corresponding FIFO registers on the positive edge of the `HCLK` clock signal.

### `Verifier` module

The `Verifier` module interfaces with the DMA memory and is responsible for verifying the correctness of data read from the memory. It receives signals related to DMA addresses, read requests, and serialized output. It also has outputs for controlling the DMA read operation and receiving the read data.

### `FIFO_Reader_Helper` module

The `FIFO_Reader_Helper` module assists in reading data from the FIFO. It receives signals related to read requests, buffer length, FIFO empty status, and FIFO data output. It provides the necessary control signals to enable reading from the FIFO and outputs the serialized data.

### `async_fifo` module

The `async_fifo` module represents the FIFO on the master side. It handles the asynchronous transfer of data between the master and slave modules. It has separate clock domains for write and read operations and includes control signals for full and empty status.

### `CPU_Registers` module

The `CPU_Registers` module represents the CPU registers and is responsible for controlling the start and completion of commands. It receives signals related to the system start, master completion, and command details. It outputs the buffer length and DMA addresses.

### `ahb3lite_master` module

The `ahb3lite_master` module represents the AHB-Lite 3 master module. It interfaces with the AHB bus and controls the communication with the slave module. It receives various signals related to address, burst type, data size, transfer type, write enable, and system start. It outputs the read data and control signals for completion and DMA details.

### `ahb3lite_slave` module

The `ahb3lite_slave` module represents the AHB-Lite 3 slave module. It interfaces with the AHB bus and handles the slave-side communication. It receives signals related to system start, address, burst type, data size, transfer type, and write enable. It controls the slave-side memory access and outputs the read data.

### `ahb3lite_memory` module

The `ahb3lite_memory` module represents the external memory accessed by the AHB-Lite 3 slave module. It receives read requests and write addresses from the slave module and outputs the corresponding read data.

## Usage

To use this AHB-Lite 3 master-slave communication design, follow these steps:

1. Instantiate the `ahb3lite_top` module and connect the required input and output ports to the respective signals in your design.

2. Configure the FIFO by calling the `configure_FIFO` task and providing the desired programmable empty and full thresholds.

3. Instantiate the remaining modules (`Verifier`, `FIFO_Reader_Helper`, `async_fifo`, `CPU_Registers`, `ahb3lite_master`, `ahb3lite_slave`, and `ahb3lite_memory

`) and connect the necessary input and output ports based on your design requirements.

4. Connect the clocks and resets to their respective modules.

5. Simulate or synthesize the design using a SystemVerilog-compatible tool.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

This design is based on the AHB-Lite 3 protocol and incorporates various modules to enable master-slave communication with DMA memory and FIFO components. Special thanks to the authors and contributors of these modules for their valuable contributions.

Feel free to contribute to this repository by creating issues or submitting pull requests to enhance the functionality or fix any issues.