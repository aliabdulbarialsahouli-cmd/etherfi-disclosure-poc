<h1>🚨 Security Disclosure: Protocol-Level DoS & Architectural Issues in Ether.fi</h1>

<p>
  <strong>Target Protocol:</strong> Ether.fi<br>
  <strong>Impacted Contract:</strong> <code>EtherFiRedemptionManager.sol</code><br>
  <strong>Researcher:</strong> Ali Al-Sahouli (Independent Smart Contract Security Researcher)<br>
  <strong>Disclosure Type:</strong> Responsible Disclosure (Case Closed / Report Rejected)<br>
  <strong>Severity:</strong> High / Medium (Design-Level DoS Risks)
</p>

<hr>

<h2>📌 Overview</h2>
<p>
  This repository documents two architectural vulnerabilities identified within the Ether.fi protocol.
</p>
<p>
  The findings demonstrate how specific design assumptions in the redemption logic can lead to denial-of-service conditions affecting protocol operations under certain execution paths. All findings were validated using deterministic Foundry-based test environments and mainnet-fork simulations prior to disclosure.
</p>

<hr>

<h2>📅 Disclosure Timeline</h2>
<ul>
  <li><strong>March 06, 2026:</strong> Identification of Forced ETH Injection DoS (High Severity) and initial PoC submission.</li>
  <li><strong>March 10, 2026:</strong> Identification of Gas-Limited Redemption Failure affecting smart contract wallet compatibility.</li>
  <li><strong>March – June 2026:</strong> Extended review period with limited feedback during triage.</li>
  <li><strong>June 2026:</strong> Report closed with classification as non-reproducible on current mainnet state.</li>
</ul>
<p>
  This repository preserves the pre-patch technical state for transparency and security research purposes.
</p>

<hr>

<h2>🐛 Vulnerability 1: DoS via Balance Invariant Assumption</h2>

<h3>1. Target Vector</h3>
<ul>
  <li><strong>Contract:</strong> <code>EtherFiRedemptionManager.sol</code></li>
  <li><strong>Function:</strong> Redemption balance verification logic</li>
</ul>

<h3>2. Issue Description</h3>
<p>The contract relies on strict equality between expected and actual ETH balance:</p>

<pre><code class="language-solidity">require(
    address(liquidityPool).balance == prevLpBalance - ethReceived,
    "Invalid liquidity pool balance"
);</code></pre>

<h3>3. Risk & Impact</h3>
<p>
  The EVM balance of an address is not strictly controlled by the contract itself and can be affected by external factors outside standard execution flow. 
  As a result, the invariant condition can fail if unexpected balance changes occur, causing transaction reverts and blocking redemption flow under certain conditions.
</p>

<h3>4. Impact Scope</h3>
<ul>
  <li>Failed redemption execution paths</li>
  <li>Potential service disruption for liquidity withdrawal logic</li>
  <li>Increased fragility of balance-dependent invariants</li>
</ul>

<h3>5. Recommendation</h3>
<p>Replace external balance checks with internal accounting state:</p>

<pre><code class="language-solidity">require(
    recordedBalance == prevRecordedBalance - ethReceived,
    "Balance mismatch detected"
);</code></pre>

<hr>

<h2>🐛 Vulnerability 2: Gas-Limited ETH Transfer Incompatibility</h2>

<h3>1. Target Vector</h3>
<ul>
  <li><strong>Contract:</strong> <code>EtherFiRedemptionManager.sol</code></li>
  <li><strong>Function:</strong> <code>_processETHRedemption</code></li>
</ul>

<h3>2. Issue Description</h3>
<p>ETH is forwarded using a fixed gas stipend:</p>

<pre><code class="language-solidity">(bool success, ) = receiver.call{value: ethReceived, gas: 10_000}("");</code></pre>

<h3>3. Risk & Impact</h3>
<p>
  Modern smart contract wallets (e.g., multisig wallets and account abstraction wallets) may require more than 10,000 gas to process incoming ETH due to additional internal validation logic. 
  This can cause failed transfers when interacting with non-EOA recipients.
</p>

<h3>4. Impact Scope</h3>
<ul>
  <li>Failed ETH withdrawals for smart contract wallets</li>
  <li>Incompatibility with ERC-4337 account abstraction systems</li>
  <li>Reduced accessibility for institutional users</li>
</ul>

<h3>5. Recommendation</h3>
<p>Use unrestricted gas forwarding with proper success validation:</p>

<pre><code class="language-solidity">(bool success, ) = receiver.call{value: ethReceived}("");
require(success, "ETH transfer failed");</code></pre>

<hr>

<h2>🛠️ Reproduction (Foundry)</h2>

<pre><code class="language-bash" git clone &lt;https://github.com/aliabdulbarialsahouli-cmd/etherfi-disclosure-poc.git;
cd etherfi-disclosure-poc
forge install</code></pre>

<p><strong>Run tests:</strong></p>
<pre><code class="language-bash">forge test --match-contract ExploitTest -vvv
forge test --match-contract RedemptionGasLimitTest -vvv</code></pre>

<hr>

<h2>⚖️ Security Note</h2>
<p>
  This repository is published for educational and research transparency purposes. All vulnerabilities were identified through independent analysis using deterministic simulation environments prior to any public patch disclosure. The intent is to contribute to safer smart contract design patterns across the Web3 ecosystem.
</p>

<hr>

<h2>📎 Closing Statement</h2>
<p>
  Smart contract security relies on verifiable execution, deterministic reasoning, and transparent design assumptions. When invariant logic depends on externally mutable state or when execution constraints are hardcoded without considering modern account abstraction systems, protocol-level risks can emerge.
</p>
