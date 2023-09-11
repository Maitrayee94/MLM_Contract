// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
    address public fees_address;

    uint256 public totalStaked;
    uint256[] RewardPercentage = [50, 20, 10, 5, 5, 4, 3, 2, 1];


    // Struct to store user staking information
    struct User {
        uint256 stakedAmount; // Amount of tokens staked
        uint256 stakingEndTime; // Time when staking ends
        uint256 StartDate;
        uint256 teamSize; // Size of the staking team
        
    }

    // Struct to store subscription details
    struct Subscription {
        uint256 tokenAmount;
        address parent;
        uint256 tier;

    }

    // Struct to store Stake_subscription details
    struct StakeSubscription {
        uint256 tokenAmount;
        address parent;
       
    }

    //Struct to Store Rewards
    struct Rewards{
        uint256 totalrewards;
    }
    struct User_children{
        address[] child;
    }

    // Mapping to store user data using their address
    mapping(address => User[]) public userStaking;

    mapping(address => mapping(uint256 => User)) public users;

    mapping(address => uint256) public userCount; // Count of stakes per user

    // Mapping to store user subscription data using their address
    mapping(address =>  Subscription) public userSubscription;

    // Mapping to store user subscription data using their address
    mapping(address => StakeSubscription) public stakeSubscription;

    mapping(address => Rewards) public userRewards;

    // Mapping to track whether an address has been referred by the owner
    mapping(address => bool) public ownerReferred;

    // Mapping to store children for each referrer
mapping(address => User_children) private referrerToChildren;

    // Mapping to track the number of referrals per tier for each referrer
    mapping(address => uint256) public maxTierReferralCounts;

    mapping(address => uint256) public rewardAmount;

    // Event to log staking action
    event TokensStaked(address indexed user, uint256 amount, uint256 stakingEndTime, uint256 id);

    // Event to log unstaking action
    event TokensUnstaked(address indexed user, uint256 amount);

    // Event to log referred from referrer
    event UserReferred(address indexed user, address indexed referrer);

    // Event to log buy token with tier
    event TokenBought(address indexed buyer, uint256 amount, uint256 tier);

    event DirectEntry(address indexed buyer, uint256 amount);

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
        fees_address = 0x7597C6c5e04E159f669B85aFDf67979Da5047ef1;
    }

    /**
    *@dev Parent Address for a given User
    */
   function getParent(address user) public view returns (address) {
    
    Subscription memory parent = userSubscription[user];
   
    return parent.parent;
}

    
    /**
     * @dev Stake tokens for a given plan, staking duration, and team size.
     * @param tokenAmount_ amount of tokens to stake.
     * @param stakingDuration_ The duration of staking in days.
     * @param teamSize_ The size of the staking team.
     */
    function stakeTokens(uint256 tokenAmount_, uint256 stakingDuration_, uint256 teamSize_, uint256 id) public {
        
    uint256 requiredAmount = tokenAmount_ * 1 ether;
        // Calculate the required staking amount based on the chosen plan

        require(stakingDuration_ == 90 || stakingDuration_ == 180 || stakingDuration_ == 365, "Invalid staking duration");

        // Calculate the end time of staking
        uint256 stakingEndTime = block.timestamp + stakingDuration_ * 1 days;
        uint256 StartDate = block.timestamp;

         // Store user staking data
    users[msg.sender][id] = User({
    stakedAmount: requiredAmount,
    stakingEndTime: stakingEndTime,
    StartDate: StartDate,
    teamSize: teamSize_  // Corrected field name to match the struct
});
    userCount[msg.sender]++;

    // Update the total staked amount
    totalStaked += requiredAmount * 1 ether;

       // userStaking[msg.sender].push(staking);

        // Transfer tokens to this contract
    token.transferFrom(msg.sender, address(this), requiredAmount);

        // Emit staking event
    emit TokensStaked(msg.sender, requiredAmount, stakingEndTime, id);
    }

    /**
     * @dev Unstake tokens and return them to the user.
     */
    function unstakeTokens(uint256 stakeId_) public {
        // Get the user's staking data
        User storage user = userStaking[msg.sender][stakeId_];
        uint256 stakedAmount = user.stakedAmount;

        // Ensure the user has staked tokens
        require(stakedAmount > 0, "No staked tokens");
        require(block.timestamp >= user.stakingEndTime, "Staking period not ended yet");
    

        // Reset user data
        delete userStaking[msg.sender];

        // Transfer tokens back to the user
        token.transfer(msg.sender, stakedAmount);

        // Emit unstaking event
        emit TokensUnstaked(msg.sender, stakedAmount);
    }

    function TotalTokenStaked(address userAddress) public view returns (uint256) {
    uint256 totalStakedByUser = 0;

    for (uint256 id = 101; id <= 100 + userCount[userAddress]; id++) {
        User memory user = users[userAddress][id];
        totalStakedByUser += user.stakedAmount * 1 ether;
    }

    return totalStakedByUser;
}

    /**
     * @dev Check if a user is referred by a given referrer.
     * @param _referrer The address of the referrer.
     * @return Whether the user is referred and the tier of the referrer.
     */
function isReferred(address _referrer) public view returns (uint256) {
    if (_referrer == owner) {
        return (ThousandUSD);
    }

    Subscription memory referrerSubscription = userSubscription[_referrer];

    if (referrerSubscription.tokenAmount == 0) {
        return (ZeroUSD);
    }

    return (referrerSubscription.tier);
}

/**
     * @dev Direct stake tokens and associate them with a referrer.
     * @param _referreladdress The address of the referrel.
     * @param _tokenAmount The amount of token.
     
     */
    function DirectStakeJoining(address _referreladdress, uint256 _tokenAmount) external {

         StakeSubscription memory subscription = stakeSubscription[msg.sender];
    require(subscription.tokenAmount == 0, "User already has a subscription");
    uint256 amount = _tokenAmount * 1 ether;
    subscription.tokenAmount = amount;
    subscription.parent = _referreladdress; 
    

       // uint256 self_stakeamount = amount;
       // uint256 remaining_tokens = amount - self_stakeamount;


        //stakeTokens(self_stakeamount, 180 , 1);

        // Assuming you have a "token" contract with a "transfer" function
        token.approve(address(this), amount);
        token.transferFrom(msg.sender, address(this), amount);
        address new_referrel;
        new_referrel = _referreladdress;
        
        for(uint256 i=0; i< 9; i++){
            if(new_referrel == owner){
                break ;
            }
            
           address parent_addr = getParent(new_referrel);
           uint256 reward_amount = RewardPercentage[i] * amount / 100;
           userRewards[parent_addr] = Rewards({totalrewards: reward_amount });
            token.transferFrom(address(this), parent_addr, reward_amount);
            
            
            new_referrel = parent_addr;
            
            

        }

        emit DirectEntry(msg.sender, _tokenAmount);
    }


    /**
     * @dev Buy tokens and associate them with a referrer.
     * @param _referrer The address of the referrer.
     * @param _tokenAmount The amount of token.
     * @param _tier The chosen referral tier.
     */
   function buyTokens(address _referrer, uint256 _tokenAmount, uint256 _tier, uint256 _fees) external {
    require(
        _tier == ZeroUSD || _tier == FiftyUSD || _tier == HundreadUSD || _tier == TwoHundreadUSD
            || _tier == FiveHundreadUSD || _tier == ThousandUSD,
        "Invalid tier value"
    );
    uint256 amount = _tokenAmount * 1 ether;
    uint256 fee = _fees * 1 ether;

    // Check for zero address
    //require(_referrer != address(0), "Invalid referrer address");

    if (_referrer == owner ) {
       Subscription memory subscription = Subscription(amount, _referrer, _tier);

        userSubscription[msg.sender] = subscription;
    }

    uint256 userTier = isReferred(_referrer);

    if (_tier == userTier) {
        require(maxTierReferralCounts[_referrer] <= maxRefferalLimit, "Already referred to maximum users.");
        maxTierReferralCounts[_referrer]++;
        Subscription memory subscription = Subscription(amount, _referrer, _tier);
        userSubscription[msg.sender] = subscription;
        referrerToChildren[_referrer].child.push(msg.sender);
    } else {
        
        // Add the child to the array of children for the referrer
        Subscription memory subscription = Subscription(amount, _referrer, _tier);
        userSubscription[msg.sender] = subscription;
    } 

    
    // Calculate fees
    //uint256 self_stakeamount = amount * 15 / 100;
    //uint256 remaing_tokens = amount - self_stakeamount;
    token.approve(address(this), amount);

    // Check if the contract has enough tokens to transfer
    require(token.balanceOf(address(this)) >= amount, "Not enough tokens in the contract");

    // Check allowance
    require(token.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");

    // Perform the transfer
    require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

    // Transfer fees to fees_address
    require(token.transfer(fees_address, fee), "Fee transfer failed");

    address new_referrel;
    new_referrel = _referrer;
    for(uint256 i=0; i< 9; i++){
        if(new_referrel == owner){
            break ;
        }
       address parent_addr = getParent(new_referrel);
       uint256 reward_amount = RewardPercentage[i] * amount / 100;
        userRewards[parent_addr] = Rewards({totalrewards: reward_amount });
       // Check if the contract has enough tokens to transfer
       require(token.balanceOf(address(this)) >= reward_amount, "Not enough tokens in the contract");

       // Perform the transfer to the parent
       require(token.transfer(parent_addr, reward_amount), "Reward transfer failed");

        new_referrel = parent_addr;
    }

    emit TokenBought(msg.sender, amount, _tier);
}
   

    function showAllParent(address user) external view returns (address[] memory) {
        address[] memory parent = new address[](9); // Initialize an array with a fixed size of 9
        address new_referrel = user;

        for (uint256 i = 0; i < 9; i++) {
            address parent_addr = getParent(new_referrel);
            parent[i] = parent_addr;

            if (new_referrel == owner) {
                break;
            } else {
                new_referrel = parent_addr;
            }
        }

        return parent;
    }


  function showAllChild(address user) external view returns (address[] memory) {
    address[] memory children = referrerToChildren[user].child;

    return children;
}



    /**
 * @dev Calculate the total rewards received by a user.
 * @param userAddress The address of the user.
 * @return The total rewards received by the user.
 */
function totalRewardsReceived(address userAddress) public view returns (uint256) {
    uint256 totalRewards = 0;

    // Calculate rewards received during DirectStakeJoining
    StakeSubscription memory directStake = stakeSubscription[userAddress];
    totalRewards += userRewards[directStake.parent].totalrewards;

    // Calculate rewards received during buyTokens
    Subscription memory referral = userSubscription[userAddress];
    totalRewards += userRewards[referral.parent].totalrewards;

    return totalRewards;
}
  
}