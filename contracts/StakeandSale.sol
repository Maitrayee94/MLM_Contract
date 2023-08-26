// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import { ERC20 } from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
/**
 * @title StakingContract
 * @dev This contract represents a staking system with different plans.
 */
contract Staking {
    address immutable owner; // The address of the contract owner

    ERC20 immutable token; // Address of the ERC20 token being staked

    // Constants defining referral limits and tier values
    uint256 public constant maxRefferalLimit = 10;
    uint256 public constant ZeroUSD = 0;
    uint256 public constant FiftyUSD = 50;
    uint256 public constant HundreadUSD = 100;
    uint256 public constant TwoHundreadUSD = 200;
    uint256 public constant FiveHundreadUSD = 500;
    uint256 public constant ThousandUSD = 1000;
    
    // Enum to define different staking plans
    enum Plan { None, Bronze, Silver, Gold, Platinum, Diamond }

    uint256 public totalStaked;

    // Struct to store user staking information
    struct User {
        uint256 stakedAmount; // Amount of tokens staked
        uint256 stakingEndTime; // Time when staking ends
        uint256 teamSize; // Size of the staking team
        Plan plan; // Chosen staking plan
        
    }

    // Struct to store subscription details
    struct Subscription {
        uint256 tokenAmount;
        address[] referrals;
        uint256 tier;
    }

    // Mapping to store user data using their address and unique ID
    mapping(address => mapping(uint256 => User)) public users;
    mapping(address => uint256) public userCount; // Count of stakes per user

    // Mapping to store user subscription data using their address
    mapping(address => Subscription) public userSubscription;

    // Mapping to track whether an address has been referred by the owner
    mapping(address => bool) public ownerReferred;

    // Mapping to track the number of referrals per tier for each referrer
    mapping(address => uint256) public maxTierReferralCounts;

    // Event to log staking action
    event TokensStaked(address indexed user, uint256 amount, Plan plan, uint256 stakingEndTime, uint256 id);

    // Event to log unstaking action
    event TokensUnstaked(address indexed user, uint256 amount, Plan plan, uint256 id);

    // Event to log referred from referrer
    event UserReferred(address indexed user, address indexed referrer);

    // Event to log buy token with tier
    event TokenBought(address indexed buyer, uint256 amount, uint256 tier);

    /**
     * @dev Modifier to restrict function access to the contract owner only.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Constructor to initialize the contract with the ERC20 token address
    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
        owner = msg.sender;
    }


      /**
 * @dev Calculate the total amount of tokens staked by a user.
 * @param userAddress The address of the user for whom the total staked amount is calculated.
 * @return The total staked amount in tokens.
 */
function TotalTokenStaked(address userAddress) public returns (uint256) {
    
    for (uint256 id = 1; id <= userCount[userAddress]; id++) {
        User memory user = users[userAddress][id];
        totalStaked += user.stakedAmount * 1 ether;
    }
    return totalStaked;
}

    /**
 * @dev Stake tokens for a given plan, staking duration, team size, and unique ID.
 * @param amount The amount of tokens to stake.
 * @param teamSize The size of the staking team.
 * @param id A unique identifier for the stake.
 */
function stakeTokens(
    uint256 amount,
    uint256 teamSize,
    uint256 id
) external {
    uint256 requiredAmount = amount * 1 ether;
    uint256 stakingDuration = 180;
    Plan plan;
    //uint256 totalStaked = TotalTokenStaked(msg.sender);
    // Calculate the required staking amount based on the total staked
    if (totalStaked <= 10000) {
        plan = Plan.None;
    } else if (totalStaked >= 10000 && totalStaked < 50000) {
        plan = Plan.Bronze;
    } else if (totalStaked >= 50000 && totalStaked < 100000) {
        plan = Plan.Gold;
    } else if (totalStaked >= 100000 && totalStaked < 250000) {
        plan = Plan.Platinum;
    } else if (totalStaked >= 250000) {
        plan = Plan.Diamond;
    } else {
        revert("Invalid plan");
    }

    // Calculate the end time of staking
    uint256 stakingEndTime = block.timestamp + stakingDuration * 1 days;

    // Store user staking data
    users[msg.sender][id] = User({
        stakedAmount: requiredAmount,
        stakingEndTime: stakingEndTime,
        teamSize: teamSize,
        plan: plan
    });
    userCount[msg.sender]++;

    // Update the total staked amount
    totalStaked += requiredAmount * 1 ether;

    // Transfer tokens to this contract
    token.transferFrom(msg.sender, address(this), requiredAmount);

    // Emit staking event
    emit TokensStaked(msg.sender, requiredAmount, plan, stakingEndTime, id);
}


    /**
     * @dev Unstake tokens and return them to the user.
     * @param id The unique identifier for the stake.
     */
    function unstakeTokens(uint256 id) external {
        // Get the user's staking data
        User storage user = users[msg.sender][id];
        uint256 stakedAmount = user.stakedAmount;

        // Ensure the user has staked tokens
        require(stakedAmount > 0, "No staked tokens");
        require(block.timestamp >= user.stakingEndTime, "Staking period not ended yet");

        // Get the user's staking plan
        Plan plan = user.plan;

        // Reset user data
        delete users[msg.sender][id];
        userCount[msg.sender]--;

        // Transfer tokens back to the user
        token.transfer(msg.sender, stakedAmount);

        // Emit unstaking event
        emit TokensUnstaked(msg.sender, stakedAmount, plan, id);
    }

    /**
     * @dev Check if a user is referred by a given referrer.
     * @param _referrer The address of the referrer.
     * @return Whether the user is referred and the tier of the referrer.
     */
    function isReferred(address _referrer) public view returns (bool, uint256) {
        if (_referrer == owner) {
            return (ownerReferred[msg.sender], ThousandUSD);
        }
        Subscription memory referrerSubscription = userSubscription[_referrer];
        uint256 length = referrerSubscription.referrals.length;

        if (referrerSubscription.tokenAmount == 0) {
            return (false, ZeroUSD);
        }

        for (uint256 i = 0; i < length; i++) {
            if (referrerSubscription.referrals[i] == msg.sender) {
                return (true, referrerSubscription.tier);
            }
        }

        return (false, referrerSubscription.tier);
    }

    /**
     * @dev Buy tokens and associate them with a referrer.
     * @param _referrer The address of the referrer.
     * @param tokenPrice_ The price of a single token.
     * @param _tier The chosen referral tier.
     */
    function buyTokens(address _referrer, uint256 tokenPrice_, uint256 _tier) external {
        require(
            _tier == ZeroUSD || _tier == FiftyUSD || _tier == HundreadUSD || _tier == TwoHundreadUSD || _tier == FiveHundreadUSD || _tier == ThousandUSD,
            "Invalid tier value"
        );

        uint256 amount;

        if (_tier == ZeroUSD) {
            amount = ZeroUSD;
        } else if (_tier == FiftyUSD) {
            amount = FiftyUSD / tokenPrice_;
        } else if (_tier == HundreadUSD) {
            amount = HundreadUSD / tokenPrice_;
        } else if (_tier == TwoHundreadUSD) {
            amount = TwoHundreadUSD / tokenPrice_;
        } else if (_tier == FiveHundreadUSD) {
            amount = FiveHundreadUSD / tokenPrice_;
        } else if (_tier == ThousandUSD) {
            amount = ThousandUSD / tokenPrice_;
        }

        if (_referrer == owner && ownerReferred[msg.sender]) {
            Subscription memory subscription = Subscription(amount, new address[](0), _tier);
            userSubscription[msg.sender] = subscription;
        }

        (bool referred, uint256 userTier) = isReferred(_referrer);

        if (userTier == ZeroUSD && !referred) {
            revert("Referral not found");
        }

        if (referred) {
            if (_tier == userTier) {
                require(maxTierReferralCounts[_referrer] <= maxRefferalLimit, "Already referred to maximum users.");
                maxTierReferralCounts[_referrer]++;
                Subscription memory subscription = Subscription(amount, new address[](0), _tier);
                userSubscription[msg.sender] = subscription;
            } else if (_tier < userTier) {
                Subscription memory subscription = Subscription(amount, new address[](0), _tier);
                userSubscription[msg.sender] = subscription;
            } else {
                revert("Invalid tier for referred user");
            }
        } else {
            revert("Referrer has not referred you");
        }

        token.transferFrom(address(this), msg.sender, amount);

        emit TokenBought(msg.sender, amount, _tier);
    }

    /**
     * @dev Add a new referral to the referrer's list of referrals.
     * @param _referral The address of the referral.
     */
    function addReferral(address _referral) external {
        require(_referral != address(0), "Invalid referral address");
        require(_referral != msg.sender, "You cannot refer yourself");

        if (msg.sender == owner) {
            ownerReferred[_referral] = true;
            return;
        }

        Subscription storage referrerSubscription = userSubscription[msg.sender];

        require(referrerSubscription.tokenAmount > 0, "You are not eligible to refer");

        for (uint256 i = 0; i < referrerSubscription.referrals.length; i++) {
            require(referrerSubscription.referrals[i] != _referral, "Referral already added");
        }

        referrerSubscription.referrals.push(_referral);

        emit UserReferred(_referral, msg.sender);
    }
}
