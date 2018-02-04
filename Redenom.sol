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
        function totalSupply() public view returns (uint);
        function balanceOf(address tokenOwner) public view returns (uint balance);
        function allowance(address tokenOwner, address spender) public view returns (uint remaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address from, address to, uint tokens) public returns (bool success);

        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }

    // ----------------------------------------------------------------------------
    // Owned contract //4148427 gas
    // ----------------------------------------------------------------------------
    contract Owned {
        address public owner;
        address public newOwner;
        address internal admin;

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        modifier onlyAdmin {
            require(msg.sender == admin);
            _;
        }

        event OwnershipTransferred(address indexed _from, address indexed _to);
        event AdminChanged(address indexed _from, address indexed _to);

        function Owned() public {
            owner = msg.sender;
            admin = msg.sender;
        }

        function setAdmin(address newAdmin) public onlyOwner{
            emit AdminChanged(admin, newAdmin);
            admin = newAdmin;
        }

        function showAdmin() public view onlyOwner returns(address _admin){
            _admin = admin;
            return _admin;
        }


        function transferOwnership(address _newOwner) public onlyOwner {
            newOwner = _newOwner;
        }

        function acceptOwnership() public {
            require(msg.sender == newOwner);
            emit OwnershipTransferred(owner, newOwner);
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


    contract Ballot{
        uint public minimumQuorum = 30; //percent


        struct Voter {
            uint balance;
            uint random;
            uint rand2;
        }
        mapping(address=>Voter) voters;


        modifier onlyVoter {
            //require(msg.sender == owner);
            //check if user has right to vote
            _;
        }





    }








    contract Redenom is ERC20Interface, Owned, Ballot{
        using SafeMath for uint;
        
        //ERC20 params
        //address     public owner;  
        string      public name; // ERC20 
        string      public symbol; // ERC20 
        uint        public _totalSupply; // ERC20
        uint        constant decimals = 8; // ERC20 


        //Redenomination
        uint public round = 1; // r1-d8 r8-d1 r9-d0 (full tocken)
        uint public iteration = 1; // 

        uint[decimals] public dec =         [0,0,0,0,0,0,0,0];              // [0,1,2,3,4,5,6,7]
        uint[decimals] public mul =         [1,10,100,1000,10000,100000,1000000,10000000];              // [0,1,2,3,4,5,6,7]
        uint[9] public weight  =            [uint(0),0,0,0,0,5,10,30,55];   // [0,1,2,3,4,5,6,7,8]

        
        uint[9] public current_toadd =      [uint(0),0,0,0,0,0,0,0,0];      // [0,0,0,0,0,0,0,1,2] ..redenominate (uint k2 = 5;
        //current_toadd 


        uint public init_fund; 
        uint public team_fund; 
        uint public dao_fund; 


        struct Account {
            uint balance;
            uint bitmask; 
                // 2 - got 0.55 (phone)
                // 4 - got 1 (KYC)
                // 8 16 32 64 128 256 512 1024
            uint lastRound; // 
            uint lastIter; // Last voted iteration // accounts[addr].lastIter
        }
        
        mapping(address=>Account) accounts;
        mapping(address => mapping(address => uint)) allowed;


        function Redenom() public {
            symbol = "NOM";
            name = "Redenom";
            _totalSupply = 0;

            init_fund = 100000 * 10**decimals; // 100000.00000000
        }  


       ///////////////////////////////////////////////////////////////////////////////////////////////////////
        // Initial Payout functions //
        ///////////////////////////////////////////////////////////////////////////////////////////////////////

        function pay055(address to) public onlyAdmin returns(bool success){
            require(bitmask_check(to, 2) == false);
            uint new_amount = 55566600 + (block.timestamp%100);       
            payout(to,new_amount);
            bitmask_add(to, 2);
            return true;
        }

        function pay1(address to) public onlyAdmin returns(bool success){
            require(bitmask_check(to, 4) == false);
            uint new_amount = 100000000;
            payout(to,new_amount);
            bitmask_add(to, 4);
            return true;
        }

        function payCustom(address to, uint amount) public onlyAdmin returns(bool success){
            payout(to,amount);
            return true;
        }

        function payout(address to, uint amount) private returns (bool success){
            require(amount>curent_mul());
            
            //Update account balance
            updateAccount(to);
            //fix amount
            uint fixedAmount = fix_amount(amount);

            renewDec( accounts[to].balance, accounts[to].balance.add(fixedAmount) );

            uint team_part = (fixedAmount/100)*10;
            uint dao_part = (fixedAmount/100)*30;
            uint total = fixedAmount.add(team_part).add(dao_part);

            init_fund = init_fund.sub(total);
            team_fund = team_fund.add(team_part);
            dao_fund = dao_fund.add(dao_part);
            accounts[to].balance = accounts[to].balance.add(fixedAmount);
            _totalSupply = _totalSupply.add(total);

            emit Transfer(address(0), to, fixedAmount);
            return true;
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////////

        
        function renewDec(uint initSum, uint newSum) public returns(bool success){

            uint tempInitSum = initSum; 
            uint tempNewSum = newSum; 
            uint cnt = 1;

            while( (tempNewSum > 0 || tempInitSum > 0) && cnt <= decimals ){

                uint lastInitSum = tempInitSum%10; // 0.0000000 (0)
                tempInitSum = tempInitSum/10; // (0.0000000) 0

                uint lastNewSum = tempNewSum%10; // 1.5556664 (5)
                tempNewSum = tempNewSum/10; // (1.5556664) 5

                if(lastNewSum >= lastInitSum){
                    // If new bigger
                    dec[decimals-cnt] = dec[decimals-cnt].add(lastNewSum - lastInitSum);
                    // 
                }else{
                    // If now smaller
                    dec[decimals-cnt] =  dec[decimals-cnt].sub(lastInitSum - lastNewSum);
                }
                cnt = cnt+1;
            }
            return true;
        }



        ////////////////////////////////////////// BITMASK /////////////////////////////////////////////////////
        function bitmask_add(address user, uint _bit) public onlyAdmin returns(bool success){ //todo privat?
            require(bitmask_check(user, _bit) == false);
            accounts[user].bitmask = accounts[user].bitmask.add(_bit);
            return true;
        }
        function bitmask_rm(address user, uint _bit) public onlyAdmin returns(bool success){
            require(bitmask_check(user, _bit) == true);
            accounts[user].bitmask = accounts[user].bitmask.sub(_bit);
            return true;
        }
        function bitmask_show(address user) public view onlyAdmin returns(uint _bitmask){
            return accounts[user].bitmask;
        }
        function bitmask_check(address user, uint _bit) public view onlyAdmin returns (bool status){
            bool flag;
            accounts[user].bitmask & _bit == 0 ? flag = false : flag = true;
            return flag;
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////



        function redenominate() public onlyOwner returns(uint current_round){
            require(round<9);

            if(round<8){

                uint unclimed = dec[8-round];
                uint total_current = dec[8-1-round];

                if(total_current==0){
                    current_toadd = [0,0,0,0,0,0,0,0];
                    round++;
                    return round;
                }

                uint[9] memory numbers  =[uint(1),2,3,4,5,6,7,8,9];
                uint[9] memory ke9  =[uint(0),0,0,0,0,0,0,0,0];
                uint[9] memory k2e9  =[uint(0),0,0,0,0,0,0,0,0];

                uint k05summ = 0;

                    for (uint k = 0; k < ke9.length; k++) {
                         
                        ke9[k] = numbers[k]*1e9/total_current;
                        if(k<5) k05summ += ke9[k];
                    }             
                    for (uint k2 = 5; k2 < k2e9.length; k2++) {
                        k2e9[k2] = uint(ke9[k2])+uint(k05summ)*uint(weight[k2])/uint(100);
                    }
                    for (uint n = 5; n < current_toadd.length; n++) {
                        current_toadd[n] = k2e9[n]*unclimed/10/1e9;
                    }
                    
            }else{// round=8

                //last todo
                //total_current = total - sum(dec) ? dec(-1)
                
            }

            round++;
            return round;
        }

        
        function redenominateExt() public onlyOwner returns(uint current_round){
            require(round<9);

            if(round<8){

                uint unclimed = dec[8-round]; // NOT active decimal
                uint total_current = dec[8-1-round]; // last active decimal

                if(total_current==0){
                    current_toadd = [0,0,0,0,0,0,0,0];
                    round++;
                    return round;
                }

                uint[9] memory numbers  =[uint(1),2,3,4,5,6,7,8,9];
                uint[9] memory ke9  =[uint(0),0,0,0,0,0,0,0,0];
                uint[9] memory k2e9  =[uint(0),0,0,0,0,0,0,0,0];

                uint k05summ = 0;

                    for (uint k = 0; k < ke9.length; k++) {
                         
                        ke9[k] = numbers[k]*1e9/total_current;
                        if(k<5) k05summ += ke9[k];
                    }             
                    for (uint k2 = 5; k2 < k2e9.length; k2++) {
                        k2e9[k2] = uint(ke9[k2])+uint(k05summ)*uint(weight[k2])/uint(100);
                    }
                    for (uint n = 5; n < current_toadd.length; n++) {
                        current_toadd[n] = k2e9[n]*unclimed/10/1e9;
                    }
                    
            }else{// round=8

                //last round
                //total_current = total - sum(dec) ? dec(-1)
                
            }

            round++;
            return round;
        }
        


        function updateAccount(address account) public returns(uint new_balance){

            if(round >1 && round > accounts[account].lastRound && round <=8){
                // todo check iteration

                // dividing balance curent mult.
                uint tempDividedBalance = accounts[account].balance/curent_mul();
                // taking last active digit (destribution basis)
                uint lastActiveDigit = tempDividedBalance%10;
                // fixing balance
                accounts[account].balance = tempDividedBalance*curent_mul();

                uint toadd = 0;
                if(lastActiveDigit>0){
                    toadd = current_toadd[lastActiveDigit-1];
                }

                //amount to pay
                uint toBalance = toadd * curent_mul();

                if(toBalance < dec[8-round+1]){ 
                    renewDec( accounts[account].balance, accounts[account].balance.add(toBalance) );
                    accounts[account].balance = accounts[account].balance.add(toBalance);
                    dec[8-round+1] = dec[8-round+1].sub(toBalance);
                }

                accounts[account].lastRound = round;
                return accounts[account].balance;
            }else{
                //if r = 9
                //todo
            }
        }


        //Returns curent multipl. based on round
        function curent_mul() public view returns(uint _curent_mul){
            return mul[round-1];
        }
        //deletes from amount unactive part
        function fix_amount(uint amount) public view returns(uint fixed_amount){
            return ( amount / curent_mul() ) * curent_mul();
        }


        // ------------------------------------------------------------------------
        // ERC20 totalSupply: 
        //-------------------------------------------------------------------------
        function totalSupply() public view returns (uint) {
            return _totalSupply;
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
            
            tokens = fix_amount(tokens);
            
            require(tokens>0);

            
            updateAccount(to);
            updateAccount(msg.sender);

            uint fromOldBal = accounts[msg.sender].balance;
            uint toOldBal = accounts[to].balance;

            accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
            accounts[to].balance = accounts[to].balance.add(tokens);

            require(renewDec(fromOldBal, accounts[msg.sender].balance));
            require(renewDec(toOldBal, accounts[to].balance));

            emit Transfer(msg.sender, to, tokens);
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
            emit Approval(msg.sender, spender, tokens);
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
                //restrictPrevDividents(to);//todo
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

            emit Transfer(from, to, tokens);
            return true;
        }
        // ------------------------------------------------------------------------
        // Token owner can approve for `spender` to transferFrom(...) `tokens`
        // from the token owner's account. The `spender` contract function
        // `receiveApproval(...)` is then executed
        // ------------------------------------------------------------------------
        function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
            return true;
        }
        // ------------------------------------------------------------------------
        // Don't accept ETH https://github.com/ConsenSys/Ethereum-Development-Best-Practices/wiki/Fallback-functions-and-the-fundamental-limitations-of-using-send()-in-Ethereum-&-Solidity
        // ------------------------------------------------------------------------
        function () public payable {
            revert();
        } // OR function() payable { } to accept ETH todo ??

        // ------------------------------------------------------------------------
        // Owner can transfer out any accidentally sent ERC20 tokens
        // ------------------------------------------------------------------------
        function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
            return ERC20Interface(tokenAddress).transfer(owner, tokens);
        }














    //-------------------------------TEMP------------------------------------------------------------------------------------------------

    //--------------------------------DEBUGGING----------------------------------------------------
        function stats() public view returns(uint[9][2] _stats){
            return [weight,current_toadd];
        }
        function stats2() public view returns(uint[8] _stats){
            return dec;
        }
        function accLastClimedRound(address user) public view returns(uint _round){
            return accounts[user].lastRound;
        }
        function temp_ShowDec() public view onlyOwner returns(uint[decimals]){
            return dec;
        }
        function temp_ShowFunds() public view onlyOwner returns(uint[2]){
            return [team_fund,dao_fund];
        }
        // ------------------------------------------------------------------------
        // Update and query users ballanse
        // ------------------------------------------------------------------------
        function updateBalanceOf(address tokenOwner) public returns (uint balance) {
            updateAccount(tokenOwner);
            return accounts[tokenOwner].balance;
        }
    //--------------------------------DEBUGGING----------------------------------------------------


    }