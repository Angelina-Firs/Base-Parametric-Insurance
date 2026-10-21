// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract VortexParametricInsurance {
    struct RiskPool {
        uint256 premiumWei;
        uint256 payoutWei;
        bool isActive;
        bytes32 conditionHash;
    }

    address payable public immutable poolAdmin;
    string public poolDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public poolCounter;
    uint256 public accumulatedFees;
    bool public isPoolHalted;

    mapping(address => bool) public authorizedOracles;
    mapping(uint256 => RiskPool) public riskPools;
    mapping(uint256 => mapping(address => bool)) public activePolicies;

    event OracleAdded(address indexed oracle);
    event PolicyPurchased(uint256 indexed poolId, address indexed policyHolder, uint256 premium);
    event PolicyCanceled(uint256 indexed poolId, address indexed policyHolder);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event PoolHaltToggled(bool isHalted);
    event RiskPoolRegistered(uint256 indexed poolId, uint256 premium, uint256 payout);
    event PayoutTriggered(uint256 indexed poolId, address indexed policyHolder, uint256 payout);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == poolAdmin, "VortexInsure: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isPoolHalted, "VortexInsure: Pool is halted");
        _;
    }

    constructor() {
        poolAdmin = payable(msg.sender);
        poolDescriptor = "Vortex Base Parametric Insurance v1";
        platformFeeBps = 250; // 2.5%
        isPoolHalted = false;
        authorizedOracles[msg.sender] = true;
    }

    // 1. addAuthorizedOracle
    function addAuthorizedOracle(address oracle) external onlyAdmin {
        require(!authorizedOracles[oracle], "VortexInsure: Already authorized");
        authorizedOracles[oracle] = true;
        emit OracleAdded(oracle);
    }

    // 2. buyInsurancePolicy
    function buyInsurancePolicy(uint256 poolId) external payable whenNotHalted {
        RiskPool storage r = riskPools[poolId];
        require(poolId > 0 && poolId <= poolCounter, "VortexInsure: Invalid ID");
        require(r.isActive, "VortexInsure: Pool inactive");
        require(!activePolicies[poolId][msg.sender], "VortexInsure: Already insured");
        require(msg.value >= r.premiumWei, "VortexInsure: Insufficient premium");

        uint256 fee = (msg.value * platformFeeBps) / 10000;
        accumulatedFees += fee;
        activePolicies[poolId][msg.sender] = true;

        if (msg.value > r.premiumWei) {
            (bool refunded, ) = payable(msg.sender).call{value: msg.value - r.premiumWei}("");
            require(refunded, "VortexInsure: Refund failed");
        }

        emit PolicyPurchased(poolId, msg.sender, r.premiumWei);
    }

    // 3. cancelPolicy
    function cancelPolicy(uint256 poolId) external {
        require(activePolicies[poolId][msg.sender], "VortexInsure: No active policy");
        activePolicies[poolId][msg.sender] = false;
        emit PolicyCanceled(poolId, msg.sender);
    }

    // 4. depositPoolTreasury
    function depositPoolTreasury() external payable whenNotHalted {
        require(msg.value > 0, "VortexInsure: Zero deposit");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. emptyPoolReserves
    function emptyPoolReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "VortexInsure: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = poolAdmin.call{value: balance}("");
        require(sent, "VortexInsure: Sweep failed");

        emit ReservesEmptied(poolAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "VortexInsure: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = poolAdmin.call{value: amount}("");
        require(sent, "VortexInsure: Harvest failed");

        emit FeesGathered(poolAdmin, amount);
    }

    // 7. haltInsurancePool
    function haltInsurancePool(bool isHalted) external onlyAdmin {
        isPoolHalted = isHalted;
        emit PoolHaltToggled(isHalted);
    }

    // 8. registerRiskPool
    function registerRiskPool(uint256 premiumWei, uint256 payoutWei, bytes32 conditionHash) external onlyAdmin returns (uint256) {
        require(premiumWei > 0 && payoutWei > premiumWei, "VortexInsure: Invalid economics");

        poolCounter++;
        riskPools[poolCounter] = RiskPool({
            premiumWei: premiumWei,
            payoutWei: payoutWei,
            isActive: true,
            conditionHash: conditionHash
        });

        emit RiskPoolRegistered(poolCounter, premiumWei, payoutWei);
        return poolCounter;
    }

    // 9. triggerOraclePayout
    function triggerOraclePayout(uint256 poolId, address policyHolder) external whenNotHalted {
        require(authorizedOracles[msg.sender], "VortexInsure: Not an oracle");
        RiskPool storage r = riskPools[poolId];
        require(r.isActive, "VortexInsure: Pool inactive");
        require(activePolicies[poolId][policyHolder], "VortexInsure: Policy not active");
        require(address(this).balance - accumulatedFees >= r.payoutWei, "VortexInsure: Insufficient liquidity");

        activePolicies[poolId][policyHolder] = false;

        (bool sent, ) = payable(policyHolder).call{value: r.payoutWei}("");
        require(sent, "VortexInsure: Payout transfer failed");

        emit PayoutTriggered(poolId, policyHolder, r.payoutWei);
    }

    // 10. updatePoolDescriptor
    function updatePoolDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "VortexInsure: Empty string");
        poolDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}