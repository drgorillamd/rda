# Use Arch Linux as base image
FROM archlinux

# Set the path to include the foundry, z3 and solc binaries we are about to install
ENV PATH="/root/.foundry/bin:/usr/bin/:/usr/local/bin/:/usr/local/eldarica:$PATH"

# Update and install required packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel wget git cmake boost ninja cvc4 python unzip && \
    pacman -Scc --noconfirm

# Build and install Z3 (solc requires <= 4.12.1)
RUN git clone --recursive https://github.com/Z3Prover/z3.git
WORKDIR /z3/
RUN git checkout z3-4.12.1
RUN python scripts/mk_make.py
WORKDIR /z3/build/
RUN make
RUN make install
WORKDIR /

# Create symbolic links for libz3
RUN ln -s /usr/lib/libz3.so /usr/lib/libz3.so.4
RUN ln -s /usr/lib/libz3.so /usr/lib/libz3.so.4.11

# Install Eldarica
RUN wget https://github.com/uuverifiers/eldarica/releases/download/v2.1/eldarica-bin-2.1.zip
RUN unzip eldarica-bin-2.1.zip
RUN mv eldarica/ /usr/local/

# Build and install solc
RUN git clone --recursive https://github.com/ethereum/solidity.git
WORKDIR /solidity/
RUN mkdir build
WORKDIR /solidity/build/
RUN cmake .. && make

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    ~/.foundry/bin/foundryup

# Set the working directory
WORKDIR /project-src

# Set the default command to run when the container starts
CMD ["bash"]