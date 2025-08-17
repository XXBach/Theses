# Theses
# A final project in University, doesn't have anything to do with SystemVerilog testbench learning, it is named DNN-SIP: An ASIP design for Deep Learning application.
# Introduction
An ASIP ( Application Specific Instruction-Set Processor ) to execute full-flow DNN 

An Idea for DNN-SIP is shown below

![DNN partitioning](https://github.com/XXBach/Theses/blob/main/DSIPpipeline_Eng.jpg)

A neural network (NN) is generally a deep learning model inspired by the way the human brain processes information. In a typical NN, each layer consists of multiple nodes that receive inputs from the previous layer and produce outputs for the next. A network is considered “deep” (DNN) when it contains more than one hidden layer between input and output, enabling it to solve more complex tasks.

Given that a DNN inherently consists of multiple layers, it can be viewed as a multi-stage pipeline architecture. Based on this perspective, we adopt the idea of assigning each layer - or parts of a layer — to one or more dedicated processing units, as the figure DNN partitioning has shown. The network is pipelined according to the number of nodes it contains. The parameters associated with each node or group of nodes are mapped to the corresponding DNN-SIP module. These modules can be connected horizontally, representing multiple layers within a DNN, or vertically, representing a specific number of nodes within a layer.

A notable feature of this pipelined arrangement is its flexibility in workload balancing. If it is not possible to evenly distribute nodes within a single layer across the vertical dimension, the first DNN-SIP in the vertical chain (denoted as x0, where x indicates the vertical index and 0 the horizontal index) is assigned the smaller partition. This unit also handles additional responsibilities such as loading data from OM for other DNN-SIP units processing the same layer.

In theory, this partitioning ensures that the processing time for each stage remains balanced, as the computational workload per DNN-SIP module is designed to be nearly equivalent.

# DNN-SIP Overall Architecture

The overall architecture can be seen below

![DNN-SIP](https://github.com/XXBach/Theses/blob/main/DNN_SIP.jpg)

As the picture shown, one single DNN-SIP contains of:

• A Controller Core is responsible for transferring data from off-chip memory (OM) to the on-chip buffers within the DNN-SIP Core, and for handling communication with other DNN-SIP modules through ports. Its instruction set is largely inspired by the RISC paradigm, ensuring simplicity and ease of implementation. 

• A DNN-SIP Core performs the required arithmetic operations for the entire DNN workload. Its instruction set is based on the VLIW principle, with each slot derived from a RISC-style micro-operation, while the core architecture is parallelized to exploit SIMD execution. 

• While shown in the figure, there will be no buses being used. Instead the connection between Controller Core and DNN-SIP Core is just wires connection. 

• In addition, DNN-SIP is designed to be scalable both vertically and horizontally, supporting flexible partitioning of a DNN across multiple modules connected in series or parallel as needed. The picture below will show the connection. 

![DNN-SIP connection](https://github.com/XXBach/Theses/blob/main/ex_connect.jpg)

# Controller Core Architecture

The Controller Core Architecture can be seen below

![Controller Core](https://github.com/XXBach/Theses/blob/main/M_controller.png)

Controller Core's design is heavily inspired by RISC, with some adjustment, the ISA of the Controller Core is inspired by a RISC-style design, with its Arithmetic and Logic fields and Data Transfer fields sharing many similarities with conventional RISC architectures. The Arithmetic and Logic Unit (ALU) is responsible for executing instructions in both the arithmetic and logical group as well as the data transfer group. This block inherits from conventional ALU designs but reduces the number of operations to six, supporting Add, Sub, Mul, SR, AND, and OR operations.

Naturally, to handle communication with external DNN-SIP modules, the internal DNN-SIP Core, and the off-chip memory (OM), additional synchronization and signaling instructions have been developed to meet these specific requirements.

The Memory Access Command Generator (MACG) generates bitstream commands for accessing the OM based on data read from the register file and OM-related instructions; the generated bitstream is then passed to the Memory Controller module for interaction with the OM. This block is implemented with a simple structure comprising two adders for the source and destination addresses and a combiner unit that merges these values into a single bitstream.

Memory Controller receives commands from the MACG, decodes them to determine the data transfer paths, and generates the corresponding read/write signals. In addition to handling internal data transfers within the DNN-SIP, this module can also transfer data to or receive data from other DNN-SIP modules. Memory Controller is a finite-state machine (FSM) that decodes the bit-stream commands issued by Memory Access Command Generator (MACG) and orchestrates data movement across the DNN-SIP. It supports both unicast and broadcast transfers of data from OM to DNN-SIP Core and in the reverse direction, also to ports to transfer data to another DNN-SIP. Broadcast mode enables reuse of feature maps when a convolution layer is partitioned across multiple DNN-SIPs, allowing one command to supply the same data to n accelerators instead of issuing n separate commands.

Mode Controller governs the overall operation of Controller Core, influencing all instruction types, particularly flow control and DNN-related instructions. It issues signals to other cores and DNN-SIP modules as needed and manages the handshaking protocol when inter-module communication is required. Mode Controller synchronizes multiple DNN-SIP modules both vertically—modules executing the same DNN layer and horizontally—modules executing successive layers. Implemented as a FSM, it decides when the local DNN-SIP Core may run, when it must stall, and when handshaking with peer modules is required to prevent conflicts such as (i) simultaneous off-chip-memory requests, (ii) misordered inter-column data transfers, or (iii) completion-rate mismatches between adjacent modules.

# DNN-SIP Core Architecture

![DNN-SIP Core](https://github.com/XXBach/Theses/blob/main/Dnn_core.jpg)

DNN-SIP Core serves as the primary compute engine for deep-learning workloads and is capable of executing all operations required by an AlexNet inference pass, including convolution, activation, max-pooling, and fully connected layers. The DNN-SIP Core departs from a conventional RISC-V pipeline and instead employs a six-stage datapath controlled by a nine-slot very-long-instruction word (VLIW). Each slot configures a specific stage or resource.

DALU integrated within the DNN-SIP core is based on the design in but incorporates minor adjustments to its input-selection logic. In the modified architecture, the multiplier (Mult) stage accepts two operands: the first is programmably chosen from 0, MLI[i], or MLI[0], while the second is selected between the constant 1 and MLK[i]. The adder stage then combines the Mult output with a second operand that can be configured as 0, MLO[i], EOA[i], or EOA[i − 1], allowing flexible accumulation and biasing within the same pipeline element.

Linearizing the activation function is essential for hardware efficiency because direct evaluation of exponential or logarithmic terms dramatically increases area and delay. The nonlinear curve is therefore partitioned into a small set of straight-line segments, and the output is obtained by linear interpolation, ensuring constant-latency computation. The LUT stores the endpoints of each segment in dedicated registers; a comparator selects the segment whose range encloses the current input and forwards the corresponding coefficients to the activation unit, which completes the interpolation with minimal logic overhead.

After the parameters of the relevant line segment have been retrieved, the ordinate yi corresponding to the given input is computed. This computation is performed inside Activation block, which consists of a cascade of arithmetic operations. Activation block design follows directly from the line equation y = ax + b. 

Given an intermediate input xI that lies on a segment with endpoints A(xA, yA) and B(xB, yB), the output yI is obtained by linear interpolation, which maps naturally onto the chained operations realized by the pipeline stages of equation

![Equation](https://github.com/XXBach/Theses/blob/main/Equation.png)

To enable DNN-SIP Core to fetch operands from on-chip buffers and write back results, an Address Decoder is required. This unit examines the instruction fields, interprets loop parameters, and generates the corresponding memory addresses. The original design produced only one address per cycle; however, because the core must often read from and write to several memories concurrently, a single-address mode limited throughput. Consequently, the widths of Slot 1 and Slot 2 were increased so that the decoder can issue multiple addresses in parallel, permitting simultaneous access to multiple buffers.

# Verification

The design will be functional verified by using a small DNN model that can be access through model4_cifar10epoch.h file. We will train and verify the model by using CIFAR-10 Dataset, extract the parameters of the model, convert those to fixed point hexa then put them in OM. The instruction for each core will be written, converted to binary and put in test_files folder. Than we will compare the result of DNN-SIP and the software one.

# ASIC synthesis

For those who want to synthesis on ASIC to compare this project to some others, I have tried to synthesize by using Cadence Genus, using 45nm technology, PDK 45nm generic, PSC belong to slow_basicCells_1v2.lib, the max frequency is set to 125MHz and gls verification, all of those are scheduled by a TCL script which will be put in the same folder as results. The results received are put in ASIC_Theses folder, which is good enough for a University Theses but is not out-performed compare to other articles since I used self-design memory instead of IP that should be used for this kind of problem, additionally I am not using any buses standard or DMA to fasten the time.

[ASIC_Theses Folder URL](https://drive.google.com/file/d/1tjTGv7_sdFpJoTdnPk6xfw9OL7jd8W3v/view?usp=sharing)

# Note

