// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TrueChain
 * @dev A decentralized verification and trust system for digital assets and claims
 * @author TrueChain Team
 */
contract TrueChain {
    
    // Struct to represent a verification claim
    struct Claim {
        uint256 id;
        address claimant;
        string dataHash;
        string description;
        uint256 timestamp;
        bool isVerified;
        uint256 verifierCount;
        mapping(address => bool) verifiers;
    }
    
    // Struct to represent a verifier
    struct Verifier {
        address verifierAddress;
        uint256 reputation;
        uint256 totalVerifications;
        bool isActive;
        uint256 registrationTime;
    }
    
    // State variables
    mapping(uint256 => Claim) public claims;
    mapping(address => Verifier) public verifiers;
    mapping(address => uint256[]) public userClaims;
    
    uint256 public claimCounter;
    uint256 public constant VERIFICATION_THRESHOLD = 3;
    uint256 public constant MIN_REPUTATION = 10;
    
    address public owner;
    
    // Events
    event ClaimSubmitted(uint256 indexed claimId, address indexed claimant, string dataHash);
    event ClaimVerified(uint256 indexed claimId, address indexed verifier);
    event ClaimApproved(uint256 indexed claimId);
    event VerifierRegistered(address indexed verifier);
    event ReputationUpdated(address indexed verifier, uint256 newReputation);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier onlyActiveVerifier() {
        require(verifiers[msg.sender].isActive, "Only active verifiers can perform this action");
        _;
    }
    
    modifier validClaim(uint256 _claimId) {
        require(_claimId > 0 && _claimId <= claimCounter, "Invalid claim ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        claimCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Submit a new verification claim
     * @param _dataHash Hash of the data/document being claimed
     * @param _description Description of the claim
     */
    function submitClaim(string memory _dataHash, string memory _description) external returns (uint256) {
        require(bytes(_dataHash).length > 0, "Data hash cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        claimCounter++;
        
        Claim storage newClaim = claims[claimCounter];
        newClaim.id = claimCounter;
        newClaim.claimant = msg.sender;
        newClaim.dataHash = _dataHash;
        newClaim.description = _description;
        newClaim.timestamp = block.timestamp;
        newClaim.isVerified = false;
        newClaim.verifierCount = 0;
        
        userClaims[msg.sender].push(claimCounter);
        
        emit ClaimSubmitted(claimCounter, msg.sender, _dataHash);
        
        return claimCounter;
    }
    
    /**
     * @dev Core Function 2: Verify a submitted claim
     * @param _claimId ID of the claim to verify
     */
    function verifyClaim(uint256 _claimId) external validClaim(_claimId) onlyActiveVerifier {
        Claim storage claim = claims[_claimId];
        
        require(claim.claimant != msg.sender, "Cannot verify your own claim");
        require(!claim.verifiers[msg.sender], "Already verified this claim");
        require(!claim.isVerified, "Claim already verified");
        
        // Add verifier to the claim
        claim.verifiers[msg.sender] = true;
        claim.verifierCount++;
        
        // Update verifier's reputation and stats
        verifiers[msg.sender].totalVerifications++;
        verifiers[msg.sender].reputation += 5;
        
        emit ClaimVerified(_claimId, msg.sender);
        emit ReputationUpdated(msg.sender, verifiers[msg.sender].reputation);
        
        // Check if claim meets verification threshold
        if (claim.verifierCount >= VERIFICATION_THRESHOLD) {
            claim.isVerified = true;
            emit ClaimApproved(_claimId);
        }
    }
    
    /**
     * @dev Core Function 3: Register as a verifier
     */
    function registerVerifier() external {
        require(!verifiers[msg.sender].isActive, "Already registered as verifier");
        
        verifiers[msg.sender] = Verifier({
            verifierAddress: msg.sender,
            reputation: MIN_REPUTATION,
            totalVerifications: 0,
            isActive: true,
            registrationTime: block.timestamp
        });
        
        emit VerifierRegistered(msg.sender);
    }
    
    // View functions
    function getClaim(uint256 _claimId) external view validClaim(_claimId) returns (
        uint256 id,
        address claimant,
        string memory dataHash,
        string memory description,
        uint256 timestamp,
        bool isVerified,
        uint256 verifierCount
    ) {
        Claim storage claim = claims[_claimId];
        return (
            claim.id,
            claim.claimant,
            claim.dataHash,
            claim.description,
            claim.timestamp,
            claim.isVerified,
            claim.verifierCount
        );
    }
    
    function getVerifier(address _verifierAddress) external view returns (
        address verifierAddress,
        uint256 reputation,
        uint256 totalVerifications,
        bool isActive,
        uint256 registrationTime
    ) {
        Verifier memory verifier = verifiers[_verifierAddress];
        return (
            verifier.verifierAddress,
            verifier.reputation,
            verifier.totalVerifications,
            verifier.isActive,
            verifier.registrationTime
        );
    }
    
    function getUserClaims(address _user) external view returns (uint256[] memory) {
        return userClaims[_user];
    }
    
    function hasVerifiedClaim(uint256 _claimId, address _verifier) external view validClaim(_claimId) returns (bool) {
        return claims[_claimId].verifiers[_verifier];
    }
    
    // Owner functions
    function deactivateVerifier(address _verifier) external onlyOwner {
        require(verifiers[_verifier].isActive, "Verifier is not active");
        verifiers[_verifier].isActive = false;
    }
    
    function updateVerificationThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        // Note: This would require a more complex implementation to handle existing claims
        // For now, it's a placeholder for future upgrades
    }
}
