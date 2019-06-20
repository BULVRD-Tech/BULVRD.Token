pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract ERC20Detailed is IERC20 {

  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
 
}

contract BLVD is ERC20Detailed {
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
    
    using SafeMath for uint256;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping (address => uint256)) private _allowed;
    
    string public constant tokenSymbol = "BLVD";
    string public constant tokenName = "BULVRD";
    uint8 public constant tokenDecimals = 18;
    uint256 public _totalSupply = 0;
    uint256 public limiter = 5;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //The Redeem event is activated when a BULVRD user redeems rewards
    event RedeemRewards(address indexed addr, uint256 rewards);
    
    //Constant values for rewards
    uint256 public referral = 35;
    uint256 public ar_drive = 15;
    uint256 public closure = 15;
    uint256 public map_drive = 10;
    uint256 public dash_drive = 10;
    uint256 public police = 10;
    uint256 public hazard = 10;
    uint256 public accident = 10;
    uint256 public traffic = 5;
    uint256 public twitter_share = 5;
    uint256 public mastodon_share = 5;
    uint256 public base_report = 5;
    uint256 public speed_sign = 1;
 
    //Keep track of BULVRD users and their redeemed rewards
    mapping(address => uint256) redeemedRewards;
    mapping(address => uint256) latestWithdrawBlock;
    
    constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        owner = msg.sender;
        maintainer = msg.sender;
        oracle = msg.sender;
        maxMintable = 50000000000 * 10**uint256(tokenDecimals);
        //initial grant
        redeemRewards(105000000000 * 10**uint256(tokenDecimals), owner);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyBy(owner) returns (bool success) {
        return IERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowed[_owner][spender];
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }
  
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
  
     function transfer(address to, uint tokens) public returns (bool success) {
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(tokens);
        _balanceOf[to] = _balanceOf[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        _balanceOf[from] = _balanceOf[from].sub(tokens);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);
        _balanceOf[to] = _balanceOf[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
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
    //This can not be reverted and stops the generation of new tokens!
    function removeOracle() public onlyBy(owner) {
        oracle = address(0);
    }
    
    //The owner can change the maintainer
    function changeMaintainer(address newMaintainer) public onlyBy(owner) {
        maintainer = newMaintainer;
    }
    
    //Allow address to redeem rewards verified from BULVRD
    function redeemRewards(uint256 rewards, address destination) public onlyBy(oracle){
         //rewards to token conversion
        uint256 reward = SafeMath.div(rewards, limiter);
        
        //Must be oracle 
        require(msg.sender == oracle, "Must be Oracle to complete");

        //The amount of rewards needs to be more than the previous redeemed amount
        require(reward > redeemedRewards[destination], "Has not earned since last redeem");

        //Make sure we have moved on since the last transaction of the give
        require(block.number > latestWithdrawBlock[destination], "Have not moved on from last block");
        
        //check if reward amount can be redeemed against supply
        uint256 total = SafeMath.add(totalMinted, reward);
        require(total <= maxMintable, "Max Mintable Reached");

        //The new rewards that is available to be redeemed
        uint256 newUserRewards = SafeMath.sub(reward, redeemedRewards[destination]);
        
        //The user's rewards balance is updated with the new reward
        _balanceOf[destination] = SafeMath.add(_balanceOf[destination], newUserRewards);
        
        //The total supply (ERC20) is updated
        _totalSupply = SafeMath.add(_totalSupply, newUserRewards);
        
        //The amount of rewards redeemed by a user is updated
        redeemedRewards[destination] = reward;
        
        //Set block status for user transaction
        latestWithdrawBlock[destination] = block.number;
        
        //Add newly created tokens to totalMinted count
        totalMinted = SafeMath.add(totalMinted, newUserRewards);
        
        //The Redeem event is triggered
        emit RedeemRewards(destination, newUserRewards);
        //Update token holder balance on chain explorers
        emit Transfer(oracle, destination, newUserRewards);
    }
    
    //This function is a workaround because this.redeemedRewards cannot be public
    //This is the limitation of the current Solidity compiler
    function redeemedRewardsOf(address destination) public view returns(uint256) {
        return redeemedRewards[destination];
    }
    
    
    //Helper methods to update rewards
     function updateLimiter(uint256 value) public onlyBy(maintainer){
         limiter = value;
     }
     
     function updateReferral(uint256 value) public onlyBy(maintainer){
         referral = value;
     }
     
     function updateTwitterShare(uint256 value) public onlyBy(maintainer){
         twitter_share = value;
     }
     
     function updateMastodonShare(uint256 value) public onlyBy(maintainer){
         mastodon_share = value;
     }
     
     function updateArDrive(uint256 value) public onlyBy(maintainer){
         ar_drive = value;
     }
     
     function updateMapDrive(uint256 value) public onlyBy(maintainer){
         map_drive = value;
     }
    
    function updateDashDrive(uint256 value) public onlyBy(maintainer){
         dash_drive = value;
     }
     
     function updatePolice(uint256 value) public onlyBy(maintainer){
         police = value;
     }
     
     function updateClosure(uint256 value) public onlyBy(maintainer){
         closure = value;
     }
     
     function updateHazard(uint256 value) public onlyBy(maintainer){
         hazard = value;
     }
     
     function updateTraffic(uint256 value) public onlyBy(maintainer){
         traffic = value;
     }
     
     function updateAccident(uint256 value) public onlyBy(maintainer){
         accident = value;
     }
     
     function updateSpeedSign(uint256 value) public onlyBy(maintainer){
         speed_sign = value;
     }
     
     function updateBaseReport(uint256 value) public onlyBy(maintainer){
         base_report = value;
     }
}