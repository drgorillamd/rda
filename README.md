# Simple reverse Dutch auction contract

- sell a fixed amount of a set token (`alotedToken`) in exchange of a variable `acceptedToken`, following a reverse Dutch auction princing.
- This contract is meant as a single-use contract (ie for a single auction), as most of the parameters are immutables.
- Price is expressed as the amount of `acceptedToken` per `tokenAloted`.
- There is a floor price, the current price being ma(floor price, current price) (optionnal, use 0 to not use it)
- Auction will only run for an ampount of time, it will then revert afterward (aloted token withdraw is then allowed by the original seller)
- `bid(..)` reverts if the auction has already been settled or has expired

## Tests
### Unit tests
Using bulloak, branched tests (fuzz strategy: cover the range of values which should be correct for the tested branch)

### Integration tests
Happy path, on a mainnet fork

### Invariant tests
2 invariants for now: balance conservation of alotedToken and tokenAccepted
This is a Foundry invariant test, so basically fuzzing on steroid -> would be more interesting to include sym exec (solc builtin/smt or third-party)

### Ityfuzz
todo: constructor and rpc server

### Z3 / Eldarica
For now, need to build the image (might take some time for z3 to compile):
`docker build -t solc-z3 --platform=linux/amd64 .`

`docker run --platform=linux/amd64 -v $(pwd):$(pwd) -w $(pwd) solc-z3 {YOUR_COMMAND}`

todo: z3 precompiles available?
todo: add a shell script to run the smtchecker on the rda contract (both z3 and eldarica)

## Style convention
Solidity style-guide