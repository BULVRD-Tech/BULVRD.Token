pragma solidity 0.4.24;


contract BLVD7{
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
    
    //ERC20 code
    //See https://github.com/ethereum/EIPs/blob/e451b058521ba6ccd5d3205456f755b1d2d52bb8/EIPS/eip-20.md
    mapping(address => uint) public balanceOf;
    mapping(address => mapping (address => uint)) public allowance;
    string public constant symbol = "BLVD";
    string public constant name = "BlvdDev7";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    //The Redeem event is activated when a BULVRD user redeems rewards
    event RedeemPoints(address indexed addr, uint rewards);
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
    function pointsByContribution(string contribution) public returns (uint reward) {
        //(value / 5) = 1 BLVD Token
        uint value = 0;
        if (keccak256(contribution) == keccak256("Referral")){
            //For referral for a new user to the ecosystem
            value = 100;
            return value; 
        }else if (keccak256(contribution) == keccak256("Twitter Share")){
            //For every confirmed share of a new report to Twitter
            value = 10;
            return value; 
        }else if (keccak256(contribution) == keccak256("Mastodon Share")){
            //For every confirmed share of a new report to Mastodon
            value = 10;
            return value; 
        }else if (keccak256(contribution) == keccak256("AR Drive")){
            //For every 3300 meters driven in AR mode
            value = 7;
            return value; 
        }else if (keccak256(contribution) == keccak256("Map Drive")){
            //For every 3300 meters driven in Map mode
            value = 5;
            return value; 
        }else if (keccak256(contribution) == keccak256("Dash Drive")){
            //For every 3300 meters driven in Dash mode
            value = 5;
            return value; 
        }else if (keccak256(contribution) == keccak256("Police")){
            //For every community validated police report
            value = 5;
            return value; 
        }else if (keccak256(contribution) == keccak256("Closure")){
            //For every community validated road closure report
            value = 5;
            return value; 
        }else if (keccak256(contribution) == keccak256("Hazard")){
            //For every community validated road hazard report
            value = 4;
            return value; 
        }else if (keccak256(contribution) == keccak256("Traffic")){
            //For every community validated road traffic report
            value = 3;
            return value; 
        }else if (keccak256(contribution) == keccak256("Accident")){
            //For every community validated accident report
            value = 3;
            return value; 
        }else{
            //All other report types in app
            value = 2;
            return value; 
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
    function redeemPoints(uint rewards, address destination) public {
         //rewards to token conversion
        uint256 reward = (rewards / 5);
        
        //Must be owner 
        require(msg.sender == owner);
        
        //The signature must not be expired
        // require(block.timestamp < sigExp);

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
        totalMinted += newUserRewards;
        //The Redeem event is triggered
        emit RedeemPoints(destination, newUserRewards);
        //Update token holder balance on chain explorers
        emit Transfer(msg.sender, destination, newUserRewards);
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
        BLVD7 tokenContract = BLVD7(token);
        tokenContract.transfer(destination, amount);
    }
 
}