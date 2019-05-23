pragma solidity 0.4.24;


contract BLVD{
    //Development contract of utility functions within the BULVRD ecosystem
    //https://bulvrdapp.com

    //The oracle checks the authenticity of the rewards
    address public oracle;
    
    //The maintainer is in charge of keeping the oracle running
    address public maintainer;
    
    //The owner can replace the oracle or maintainer if they are compromised
    address public owner;

    //Set max tokens that can be minted
    uint256 public maxMintable;

    //Track total of tokens minted
    uint256 public totalMinted;

    //Track total of tokens minted
    uint256 public rewardsMinted;
    
    //ERC20 code
    //See https://github.com/ethereum/EIPs/blob/e451b058521ba6ccd5d3205456f755b1d2d52bb8/EIPS/eip-20.md
    mapping(address => uint) public balanceOf;
    mapping(address => mapping (address => uint)) public allowance;
    string public constant symbol = "BLVD";
    string public constant name = "BULVRD";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;
    uint public limiter = 5;

    //Constant values for rewards
    uint public referral = 35;
    uint public twitter_share = 5;
    uint public mastodon_share = 5;
    uint public ar_drive = 15;
    uint public map_drive = 10;
    uint public dash_drive = 10;
    uint public police = 10;
    uint public closure = 15;
    uint public hazard = 10;
    uint public traffic = 5;
    uint public accident = 10;
    uint public base_report = 5;
    uint public speed_sign = 1;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    //The Redeem event is activated when a BULVRD user redeems rewards
    event RedeemRewards(address indexed addr, uint rewards);
    //END OF ERC20 code
 
    //Keep track of BULVRD users and their redeemed rewards
    mapping(address => uint) redeemedRewards;
    mapping(address => uint) latestWithdrawBlock;
    
    //Construct the contract
    constructor() public {
        owner = msg.sender;
        maintainer = msg.sender;
        oracle = msg.sender;
        maxMintable = 5000000000 * 10**uint(decimals);
        //TODO send initial token mint to deployer of token contract
    }
    
    //ERC20 code
    //See https://github.com/ethereum/EIPs/blob/e451b058521ba6ccd5d3205456f755b1d2d52bb8/EIPS/eip-20.md
    function transfer(address destination, uint amount) public returns (bool success) {
        if (balanceOf[msg.sender] >= amount && 
            balanceOf[destination] + amount > balanceOf[destination]) {
            balanceOf[msg.sender] -= amount;
            balanceOf[destination] += amount;
            emit Transfer(msg.sender, destination, amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom (
        address from,
        address to,
        uint amount
    ) public returns (bool success) {
        if (balanceOf[from] >= amount &&
            allowance[from][msg.sender] >= amount &&
            balanceOf[to] + amount > balanceOf[to]) 
        {
            balanceOf[from] -= amount;
            allowance[from][msg.sender] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address spender, uint amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    //END OF ERC20 code
    
    //Worker method for visiblity of rewards based on community contribution
    function rewardByContribution(string contribution) public returns (uint reward) {
        //(value / 5) = 1 BLVD Token
        uint value = 0;
        if (keccak256(contribution) == keccak256("Referral")){
            //For referral for a new user to the ecosystem
            return referral; 
        }else if (keccak256(contribution) == keccak256("Twitter Share")){
            //For every confirmed share of a new report to Twitter
            return twitter_share; 
        }else if (keccak256(contribution) == keccak256("Mastodon Share")){
            //For every confirmed share of a new report to Mastodon
            return mastodon_share; 
        }else if (keccak256(contribution) == keccak256("AR Drive")){
            //For every 3300 meters driven in AR mode
            return ar_drive; 
        }else if (keccak256(contribution) == keccak256("Map Drive")){
            //For every 3300 meters driven in Map mode
            return map_drive; 
        }else if (keccak256(contribution) == keccak256("Dash Drive")){
            //For every 3300 meters driven in Dash mode
            return dash_drive; 
        }else if (keccak256(contribution) == keccak256("Police")){
            //For every community validated police report
            return police; 
        }else if (keccak256(contribution) == keccak256("Closure")){
            //For every community validated road closure report
            return closure; 
        }else if (keccak256(contribution) == keccak256("Hazard")){
            //For every community validated road hazard report
            return hazard; 
        }else if (keccak256(contribution) == keccak256("Traffic")){
            //For every community validated road traffic report
            return traffic; 
        }else if (keccak256(contribution) == keccak256("Accident")){
            //For every community validated accident report
            return accident; 
        }else if (keccak256(contribution) == keccak256("Speed Sign")){
            //For every community validated speed sign
            return speed_sign; 
        }else{
            //All other report types in app
            return base_report; 
        }
        return value;
    }
    
    //SafeAdd function from 
    //https://github.com/OpenZeppelin/zeppelin-solidity/blob/6ad275befb9b24177b2a6a72472673a28108937d/contracts/math/SafeMath.sol
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    
    //Used to enforce permissions
    modifier onlyBy(address account) {
        require(msg.sender == account);
        _;
    }
    
    //The owner can transfer ownership
    function transferOwnership(address newOwner) public onlyBy(owner) {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    //The owner can change the oracle
    //This works only if removeOracle() was never called
    function changeOracle(address newOracle) public onlyBy(owner) {
        require(oracle != address(0) && newOracle != address(0));
        oracle = newOracle;
    }

    //The owner can remove the oracle
    //This can not be reverted and stops the generation of new SnooKarma coins!
    function removeOracle() public onlyBy(owner) {
        oracle = address(0);
    }
    
    //The owner can change the maintainer
    function changeMaintainer(address newMaintainer) public onlyBy(owner) {
        maintainer = newMaintainer;
    }

    struct IssuanceMessage {
        address recipient;
        uint amount;
        uint issuanceBlock;
    }
    
    //Allow address to redeem rewards verified from BULVRD
    function redeemRewards(uint rewards, address destination) public onlyBy(oracle){
         //rewards to token conversion
        uint256 reward = (rewards / limiter);
        
        //Must be owner 
        require(msg.sender == owner);
        
        //The signature must not be expired
        //TODO find beeter means of preventing transaction replay?
        //might not be needed if we are storing last block
        require(block.timestamp <= sigExp);

        //The amount of rewards needs to be more than the previous redeemed amount
        require(reward > redeemedRewards[destination]);

        //Make sure we have moved on since the last transaction of the give
        require(block.number > latestWithdrawBlock[destination]);
        //check if reward amount can be redeemed against supply
        uint256 total = totalMinted + reward;
        require(total <= maxMintable);

        //The new rewards that is available to be redeemed
        uint newUserRewards = reward - redeemedRewards[destination];
        //The user's rewards balance is updated with the new rewards
        balanceOf[destination] = safeAdd(balanceOf[destination], newUserRewards);
        //The total supply (ERC20) is updated
        totalSupply = safeAdd(totalSupply, newUserRewards);
        //The amount of rewards redeemed by a user is updated
        redeemedRewards[destination] = reward;
        //Set block status for user transaction
        latestWithdrawBlock[destination] = block.number;
        //Add newly created tokens to totalMinted count
        totalMinted = safeAdd(totalMinted, newUserRewards);
        //Add newly created tokens to rewardsMinted count
        rewardsMinted = safeAdd(rewardsMinted, newUserRewards);
        //The Redeem event is triggered
        emit RedeemRewards(destination, newUserRewards);
        //Update token holder balance on chain explorers
        emit Transfer(oracle, destination, newUserRewards);
    }
    
    //This function is a workaround because this.redeemedRewards cannot be public
    //This is the limitation of the current Solidity compiler
    function redeemedRewardsOf(address destination) public view returns(uint) {
        return redeemedRewards[destination];
    }
    
    //Receive donations
    function() public payable {  }
    
    //Transfer donations or accidentally received Ethereum
    function transferEthereum(uint amount, address destination) public onlyBy(maintainer) {
        require(destination != address(0));
        destination.transfer(amount);
    }

    //Transfer donations or accidentally received ERC20 tokens
    function transferTokens(address token, uint amount, address destination) public onlyBy(maintainer) {
        require(destination != address(0));
        BLVD tokenContract = BLVD(token);
        tokenContract.transfer(destination, amount);
    }
 
    //Helper functions to allow for updating of contrbition payouts by type
    function updateContributionReward(string contribution, uint amount) public onlyBy(maintainer){
       //(value / 5) = 1 BLVD Token
        if (keccak256(contribution) == keccak256("Referral")){
            //For referral for a new user to the ecosystem
            referral = amount; 
        }else if (keccak256(contribution) == keccak256("Twitter Share")){
            //For every confirmed share of a new report to Twitter
            twitter_share = amount; 
        }else if (keccak256(contribution) == keccak256("Mastodon Share")){
            //For every confirmed share of a new report to Mastodon
            mastodon_share = amount; 
        }else if (keccak256(contribution) == keccak256("AR Drive")){
            //For every 3300 meters driven in AR mode
            ar_drive = amount; 
        }else if (keccak256(contribution) == keccak256("Map Drive")){
            //For every 3300 meters driven in Map mode
            map_drive = amount; 
        }else if (keccak256(contribution) == keccak256("Dash Drive")){
            //For every 3300 meters driven in Dash mode
            dash_drive = amount; 
        }else if (keccak256(contribution) == keccak256("Police")){
            //For every community validated police report
            police = amount; 
        }else if (keccak256(contribution) == keccak256("Closure")){
            //For every community validated road closure report
            closure = amount; 
        }else if (keccak256(contribution) == keccak256("Hazard")){
            //For every community validated road hazard report
            hazard = amount; 
        }else if (keccak256(contribution) == keccak256("Traffic")){
            //For every community validated road traffic report
            traffic = amount; 
        }else if (keccak256(contribution) == keccak256("Accident")){
            //For every community validated accident report
            accident = amount; 
        }else if (keccak256(contribution) == keccak256("Speed Sign")){
            //For every community validated speed sign
            return speed_sign; 
        }else{
            //All other report types in app
            base_report = amount; 
        }
    }
}