pragma solidity ^0.4.18;
       
// -------------------- SAFE MATH ----------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}












contract Redenom is ERC20Interface, Owned{
    using SafeMath for uint;

    
    //ERC20 params
    //address     public owner;  
    string      public name;
    string      public symbol;
    uint        public _totalSupply;
    uint        constant decimals = 8;


    //Redenomination
    uint public round = 1; // r1-d8 r8-d1

    uint[decimals] public dec =     [0,0,0,0,0,0,0,0]; // [0,1,2,3,4,5,6,7]
    uint[9] public weight  =        [uint(0),0,0,0,0,5,10,30,55]; // [0,1,2,3,4,5,6,7,8]
    uint[9] public current_toadd =  [uint(0),0,0,0,0,0,0,0,0]; // [0,1,2,3,4,5,6,7,8]

    uint total_old;
    uint total_new;

    //DIVIDENT params
    uint pointMultiplier = 10e18;
    uint public totalDividendPoints;
    uint public unclaimedDividends;

    struct Account {
        uint balance;
        uint lastDividendPoints; 
    }
    
    mapping(address=>Account) accounts;
    mapping(address => mapping(address => uint)) allowed;


    function Redenom() public {
        symbol = "FTL";
        name = "Fractal";

        owner = msg.sender;
        _totalSupply = 1000 * 10**uint(decimals);
        accounts[owner].balance = _totalSupply;
        Transfer(address(0), owner, _totalSupply);

    }  

//--------------------------------DEBUGGING----------------------------------------------------
    function stats() constant returns(uint[9][2] stats){
        return [weight,current_toadd];
    }
    function stats2() constant returns(uint[8] stats){
        return dec;
    }
//--------------------------------DEBUGGING----------------------------------------------------




    function redenominate() public onlyOwner returns(uint current_round){
        require(msg.sender == owner);
        require(round<9);

        if(round<8){

            total_old = dec[8-round];
            total_new = dec[8-1-round];

            uint[9] memory numbers  =[uint(1),2,3,4,5,6,7,8,9];
            uint[9] memory ke9  =[uint(0),0,0,0,0,0,0,0,0];
            uint[9] memory k2e9  =[uint(0),0,0,0,0,0,0,0,0];

            uint k05summ = 0;

                for (uint k = 0; k < ke9.length; k++) {
                     
                    ke9[k] = numbers[k]*1e9/total_new;
                    if(k<5) k05summ += ke9[k];
                }             
                for (uint k2 = 5; k2 < k2e9.length; k2++) {
                    k2e9[k2] = uint(ke9[k2])+uint(k05summ)*uint(weight[k2])/uint(100);
                }
                for (uint n = 5; n < current_toadd.length; n++) {
                    current_toadd[n] = k2e9[n]*total_old/10/1e9;
                }
                
        }else{
            //last round
            total_old = dec[8-round];

        }

        round++;
        return round;
    }


    // ------------------------------------------------------------------------
    // ERC20 totalSupply: 
    //-------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - accounts[address(0)].balance;
    }
    // ------------------------------------------------------------------------
    // ERC20 balanceOf: Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    // ------------------------------------------------------------------------
    // ERC20 allowance:
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // ERC20 transfer:
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        if(accounts[to].balance == 0) {
            restrictPrevDividents(to);
        }
        updateAccount(to);
        updateAccount(msg.sender);

        uint fromOldBal = accounts[msg.sender].balance;
        uint toOldBal = accounts[to].balance;

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[msg.sender].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        Transfer(msg.sender, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // ERC20 approve:
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // ERC20 transferFrom:
    // Transfer `tokens` from the `from` account to the `to` account
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if(accounts[to].balance == 0) {
            restrictPrevDividents(to);
        }
        updateAccount(from);
        updateAccount(to);

        uint fromOldBal = accounts[from].balance;
        uint toOldBal = accounts[to].balance;

        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[from].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }












    //--------------------------DIV----------------------------------------
    //Function assigns users lastDividendPoints curent totalDividendPoints value
    function restrictPrevDividents(address user) internal returns (bool success) {
        accounts[user].lastDividendPoints = totalDividendPoints;
        return true;
    }

    //divient to disburse
    function dividendsOwing(address account) internal view returns(uint) {
        var newDividendPoints = totalDividendPoints - accounts[account].lastDividendPoints;
        return (accounts[account].balance * newDividendPoints) / pointMultiplier;
    }

    //todo renew DEC
    function updateAccount(address account) internal {
        var owing = dividendsOwing(account);
        if(owing > 0) {
            unclaimedDividends -= owing;
            accounts[account].balance += owing;
            accounts[account].lastDividendPoints = totalDividendPoints;
        }
    }

    function disburse(uint amount) public {
        totalDividendPoints += (amount * pointMultiplier / _totalSupply);
        _totalSupply += amount;
        unclaimedDividends += amount;
    }
    //--------------------------DIV----------------------------------------
  


//-------------------------------------DEC----------------------------------------------------------

    function renewDec(uint initSum, uint newSum) internal returns(bool success){

        uint tempInitSum = initSum; //9876 +2
        uint tempNewSum = newSum; //9878

        uint cnt = 1;

        while(tempNewSum > 0 && cnt <= decimals){

            uint lastInitSum = tempInitSum%10;
            tempInitSum = tempInitSum/10;

            uint lastNewSum = tempNewSum%10;
            tempNewSum = tempNewSum/10; 

            if(lastNewSum > lastInitSum){
                dec[decimals-cnt] = dec[decimals-cnt].add(lastNewSum - lastInitSum);
            }else{
                dec[decimals-cnt] =  dec[decimals-cnt].sub(lastInitSum - lastNewSum);
            }

            cnt = cnt+1;
        }
        return true;
    }


    //Returns digit count 
    function countDigits(uint number) internal pure returns (uint digits) {
        uint count = 0;
        while (number != 0) {
            count = count+1;
            number = number/10;
        }
        return count;
    }
    //Splits the number [87657,6]
    function splitNum(uint number) internal pure returns (uint[2] result) {
        return [number/10,number%10];
    }

//-------------------------------------DEC----------------------------------------------------------