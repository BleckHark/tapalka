// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract clicer{
    struct User{
        string name;
        uint256 balance;
        uint256 clicks;
        uint256 clickMultiplier;
        uint256 withdrawableAmount;
        uint256 lastClickTime;
    }
        
    User public user1;
    
    mapping (address => User) public users;
    mapping (address => bool)public isRegistered;
    address public admin;
    uint256 public totalClicks;
    uint256 public totalUsers;
    event UserRegistered(address indexed userAddress, string name, address indexed referrer);
    event ReferralBonusPaid(address indexed referrer, uint amount);
    event Clicked(address indexed userAddress, uint256 amountEarned);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event UpgradePurchased(address indexed userAddress, uint256 newMultiplier);
    event AdminWithdraw(address indexed userAddress, uint256 amount);
    uint constant REFERRAL_BONUS = 500;
    modifier onluRegistered(){
        require(isRegistered[msg.sender], "User not register.");
        _;
    }
     modifier cooldownCheck() {
        require(block.timestamp >= users[msg.sender].lastClickTime + 10, "Cooldown period not over.");
        _;
    }
    constructor() {
        admin = msg.sender; 
    }
    function registerUser(string memory _name, address _referrer)public  {
        require(!isRegistered[msg.sender], "User already registered.");
        users[msg.sender] = User ({
            name: _name,
            balance: 0,
            clicks: 0,
            clickMultiplier: 1,
            withdrawableAmount: 0,
            lastClickTime: 0
        });
        emit UserRegistered(msg.sender, _name, _referrer);
        if(_referrer != address(0) && isRegistered[_referrer]){
            users[_referrer].balance += REFERRAL_BONUS;
            emit ReferralBonusPaid(_referrer, REFERRAL_BONUS);
        }
    }
    
    function click ()public  onluRegistered cooldownCheck{
        User storage user = users[msg.sender];
        user.clicks += 1;
        if (block.timestamp >= user.lastClickTime + 10){
            user.balance += user.clickMultiplier;
            emit Clicked(msg.sender, user.clickMultiplier );
        } else {user.balance += user.clickMultiplier * 2;
        emit Clicked(msg.sender, user.clickMultiplier * 2);
        user.lastClickTime = block.timestamp;
        totalClicks++;
    }
    }
    function transfer(address _recipient, uint _amount) public onluRegistered {
        require(users[msg.sender].balance >= _amount, "INSUFFICIENT BALANCE");
            users[msg.sender].balance -= _amount;
            users[_recipient].withdrawableAmount += _amount;
        emit Transfer(msg.sender, _recipient, _amount);
    }
    function purchaseUpgrade()public onluRegistered{
        User storage user = users[msg.sender];
        require(user.balance >= totalClicks / totalUsers, "Not enough balance to purchase upgade");
        user.balance -= 1;
        emit UpgradePurchased(msg.sender, user.clickMultiplier);
    }
    function adminWithdraw(address userAddress, uint amount)public {
        require(msg.sender == admin, "Onli admin can Withdraw.");
        User storage user = users[userAddress];
        require(user.balance >= amount, "Insufficent balance for withdrow");
        user.balance -= amount;
        emit AdminWithdraw(userAddress, amount);
    }
}
