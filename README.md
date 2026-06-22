🚨 Security Disclosure: Protocol-Level DoS & Architectural Issues in Ether.fi
Target Protocol: Ether.fi
Impacted Contract: EtherFiRedemptionManager.sol
Researcher: Ali Al-Sahouli (Independent Smart Contract Security Researcher)
Disclosure Type: Responsible Disclosure (Case Closed / Report Rejected)
Severity: High / Medium (Design-Level DoS Risks)
📌 Overview
This repository documents two architectural vulnerabilities identified within the Ether.fi protocol.
The findings demonstrate how specific design assumptions in the redemption logic can lead to denial-of-service conditions affecting protocol operations under certain execution paths.
All findings were validated using deterministic Foundry-based test environments and mainnet-fork simulations prior to disclosure.
📅 Disclosure Timeline
March 06, 2026: Identification of Forced ETH Injection DoS (High Severity) and initial PoC submission.
March 10, 2026: Identification of Gas-Limited Redemption Failure affecting smart contract wallet compatibility.
March – June 2026: Extended review period with limited feedback during triage.
June 2026: Report closed with classification as non-reproducible on current mainnet state.
This repository preserves the pre-patch technical state for transparency and security research purposes.
🐛 Vulnerability 1: DoS via Balance Invariant Assumption
Target
Contract: EtherFiRedemptionManager.sol
Function: Redemption balance verification logic
Issue
The contract relies on strict equality between expected and actual ETH balance:
Solidity
require(
    address(liquidityPool).balance == prevLpBalance + ethReceived,
    "Invalid liquidity pool balance"
);
Risk
The EVM balance of an address is not strictly controlled by the contract itself and can be affected by external factors outside standard execution flow.
As a result, the invariant condition can fail if unexpected balance changes occur, causing transaction reverts and blocking redemption flow under certain conditions.
Impact
Failed redemption execution paths
Potential service disruption for liquidity withdrawal logic
Increased fragility of balance-dependent invariants
Recommendation
Replace external balance checks with internal accounting state:
Solidity
require(
    recordedBalance == prevRecordedBalance + ethReceived,
    "Balance mismatch detected"
);
🐛 Vulnerability 2: Gas-Limited ETH Transfer Incompatibility
Target
Contract: EtherFiRedemptionManager.sol
Function: _processETHRedemption
Issue
ETH is forwarded using a fixed gas stipend:
Solidity
(bool success, ) = receiver.call{value: ethReceived, gas: 10_000}("");
Risk
Modern smart contract wallets (e.g., multisig wallets and account abstraction wallets) may require more than 10,000 gas to process incoming ETH due to additional internal validation logic.
This can cause failed transfers when interacting with non-EOA recipients.
Impact
Failed ETH withdrawals for smart contract wallets
Incompatibility with ERC-4337 account abstraction systems
Reduced accessibility for institutional users
Recommendation
Use unrestricted gas forwarding with proper success validation:
Solidity
(bool success, ) = receiver.call{value: ethReceived}("");
require(success, "ETH transfer failed");
🛠️ Reproduction (Foundry)
Bash
git clone <repo-url>
cd etherfi-disclosure-poc
forge install
Run tests:
Bash
forge test --match-contract ExploitTest -vvv
forge test --match-contract RedemptionGasLimitTest -vvv
⚖️ Security Note
This repository is published for educational and research transparency purposes.
All vulnerabilities were identified through independent analysis using deterministic simulation environments prior to any public patch disclosure.
The intent is to contribute to safer smart contract design patterns across the Web3 ecosystem.
📎 Closing Statement
Smart contract security relies on verifiable execution, deterministic reasoning, and transparent design assumptions.
When invariant logic depends on externally mutable state or when execution constraints are hardcoded without considering modern account abstraction systems, protocol-level risks can emerge.
