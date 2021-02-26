pragma solidity ^0.5.12;

import "./ITRC20.sol";
import "./token/SafeMath.sol";
import "./token/Ownable.sol";
import "./juslink.sol";

contract DE is Ownable {

    uint256 internal RICFEE = 10; // div 1000 = 0.1%
    uint256 internal COINFEE = 35; // div 1000 = 0.35%
    address payable devadr = address(0x5b3c0F6A2Cd0F4853e3663D67621c46626c11fB2);
    struct User {
        address addr;
        bool exists;
        Supply[] _supply;
        Borrow[] _borrow;
    }

    struct Supply {
        bytes32 token;
        uint256 amount;
        uint256 reward;
        bool collateral;
        uint256 lastchange;
    }

    struct Borrow {
        bytes32 token;
        uint256 amount;
        uint256 interest;
        uint256 rate;
        uint256 repay;
        uint256 borrowtime;
        uint256 lastchange;
    }

    struct IDToken {
        string id;
        bytes32 tokenbyte;
        uint8 decimals;
        uint256 totalsupply;
        uint256 totalborrow;
        uint256 totalrate;
        uint256 totalrepay;
        uint256 supplyinterest;
        uint256 borrowinterest;
    }
    struct Interest {
        bytes32 token;
        uint256 supply;
        uint256 borrow;
        uint256 maxtoken;
    }
    
    Interest[] public interest_;

    mapping(address => User) private _users;
    mapping(address => Supply) private _supply;
    mapping(address => Borrow) private _borrow;

    User[] _user;
    uint256 userLength = _user.length;
    IDToken[] public _tokenID;

    mapping(bytes32 => address) public tokens;

    ITRC20 internal TRC20Interface;
    PriceConsumer internal PriceInterface;

    constructor(PriceConsumer _PriceAddress) public {
        PriceInterface = _PriceAddress;
        bytes32 symbol_ = stringToBytes32('TRX');
        
         interest_.push(Interest(stringToBytes32('RET'),42000,42030,31000000000000));
         interest_.push(Interest(stringToBytes32('RET'),21000,21030,51000000000000));
         interest_.push(Interest(stringToBytes32('RET'),4000,4030,60000000000000));
         interest_.push(Interest(stringToBytes32('RET'),250,280,1001000000000000));
         interest_.push(Interest(stringToBytes32('RET'),200,230,10001000000000000));
         interest_.push(Interest(stringToBytes32('RET'),180,210,60000000000000000));
         interest_.push(Interest(stringToBytes32('RET'),150,180,100000000000000000));
         
         interest_.push(Interest(stringToBytes32('TRX'),80,110,200000000000));
         interest_.push(Interest(stringToBytes32('TRX'),60,90,500000000000));
         
         interest_.push(Interest(stringToBytes32('BTC'),35,110,100000000));
         interest_.push(Interest(stringToBytes32('BTC'),25,90,200000000));
         
         interest_.push(Interest(stringToBytes32('USDT'),110,140,100000000000000000000000));
         interest_.push(Interest(stringToBytes32('USDT'),80,110,200000000000000000000000));
         
         interest_.push(Interest(stringToBytes32('RIC'),110,140,100000000000000000000000));
         interest_.push(Interest(stringToBytes32('RIC'),80,110,200000000000000000000000));
         
         interest_.push(Interest(stringToBytes32('ETH'),45,75,2000000000000000000));
         interest_.push(Interest(stringToBytes32('ETH'),35,65,2000000000000000000));
         interest_.push(Interest(stringToBytes32('ETH'),25,55,10000000000000000000));
        
        
        _tokenID.push(IDToken({
            id: 'TRX',
            tokenbyte: symbol_,
            decimals: 6,
            totalsupply: 0,
            totalborrow: 0,
            totalrate: 0,
            totalrepay: 0,
            supplyinterest: 80,
            borrowinterest: 110
        }));
        emit RateChange(stringToBytes32('TRX'),80,110,uint256(block.timestamp));
    }


    event SupplyToken(address indexed from_, bytes32 tokenid_, uint256 amount_);
    event BorrowToken(address indexed from_, bytes32 tokenid_, uint256 amount_);
    event RepayToken(address indexed from_, bytes32 tokenid_, uint256 amount_);
    event RateChange(bytes32 tokenid_, uint256 srate_, uint256 brate_, uint256 time_);


    function getPrice(bytes32 _tokens) internal view returns(uint256) {
        return PriceInterface.getPrice(_tokens);
    }

    function UpdateJustlink(PriceConsumer _newaddress) public onlyOwner returns(bool) {
        PriceInterface = _newaddress;
        return true;
    }

    function fee() public view returns(uint256 _RICFEE, uint256 _COINFEE) {
        return (RICFEE, COINFEE);
    }

    function stringToBytes32(string memory source) internal pure returns(bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns(string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function addNewToken(string memory tokenname_, address address_) public onlyOwner returns(bool) {
        bytes32 symbol_ = stringToBytes32(tokenname_);
        tokens[symbol_] = address_;

        TRC20Interface = ITRC20(address_);
        uint8 dec = TRC20Interface.decimals();

        _tokenID.push(IDToken({
            id: tokenname_,
            tokenbyte: symbol_,
            decimals: dec,
            totalsupply: 0,
            totalborrow: 0,
            totalrate: 0,
            totalrepay: 0,
            supplyinterest: 0,
            borrowinterest: 0
        }));

        return true;
    }

    function removeToken(string memory tokenname_) public onlyOwner returns(bool) {
        bytes32 symbol_ = stringToBytes32(tokenname_);
        require(tokens[symbol_] != address(0));
        delete(tokens[symbol_]);
        return true;
    }

    function supply(bytes32 _tokens, uint256 _amt) public payable {
        if(_tokens != 'TRX'){
        
        address contract_ = tokens[_tokens];
        TRC20Interface = ITRC20(contract_);

        uint256 usertokenbalance = TRC20Interface.balanceOf(msg.sender);

        uint256 _allowance = TRC20Interface.allowance(msg.sender, address(this));

        require(_allowance > 0, "Msg :: Please approve token first");

        require(usertokenbalance >= _amt, "Msg :: Insufficient token balance");

        TRC20Interface.transferFrom(msg.sender, address(this), _amt);

        }else{
            
             require(msg.value > 1e6, "Amount cant zero!");
             
             _amt = msg.value;
             
        }
        
        User storage user = _users[msg.sender];
        
        if (!user.exists) {
            user.exists = true;
            user.addr = msg.sender;
            pushsupply(_tokens, _amt, msg.sender);

        } else {
            bool tokenexists = false;
            for (uint256 i = 0; i < user._supply.length; i++) {
                Supply storage supp = user._supply[i];
                if (supp.token == _tokens) {
                    tokenexists = true;
                    supp.amount += _amt;
                    break;
                }
            }
            if (!tokenexists) {
                pushsupply(_tokens, _amt, msg.sender);
            }
        }
        changeRate(_tokens, getSupplyInterest(_tokens), getBorrowInterest(_tokens));
        _changeliquidity(_tokens, _amt, 0, 0, 0);

        emit SupplyToken(msg.sender, _tokens, _amt);


    }

    
    
     function borrow(bytes32 _tokens, uint256 _amt) public returns(bool) {

        uint256 dec = uint256(_getdecimals(_tokens));
        uint256 price = getPrice(_tokens);
        uint256 amt_inUSD = (_amt / (10 ** dec)) * price;
        uint256 collateral_amt = _getcollateral(msg.sender);
        uint256 borrow_amt = _getborrow(msg.sender);
        require(amt_inUSD + borrow_amt <= ((collateral_amt * 4) / 10), "Collateral is to low.");
        
        User storage user = _users[msg.sender];
        bool tokenexists = false;
            for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
                if (borr.token == _tokens) {
                    tokenexists = true;
                    borr.amount += _amt;
                    break;
                }
            }
            if (!tokenexists) {
                pushborrow(_tokens, _amt, msg.sender);
            }
        
        _changeliquidity(_tokens, 0, _amt, 0, 0);
        _changeminliquidity(_tokens, _amt, 0, 0, 0);

        if (_tokens == 'TRX') {
            msg.sender.transfer(_amt);
        } else {
            if (_tokens == 'RIC') {
                _safetokentransfer(_tokens, msg.sender, _amt);
            }else{
                _safetokentransfer(_tokens, msg.sender, _amt);
            }
        }
        _addreward(msg.sender);
        _addrate(msg.sender);
        emit BorrowToken(msg.sender, _tokens, _amt);
        return true;

    }
    
    function getBorrowlist(address _guy,uint256 _index)public view returns(uint256 _length,bytes32 _token,uint256 _amount,uint256 _interest,uint256 _rate,uint256 _repay,uint256 _borrowtime,uint256 _lastchange){
        User storage user = _users[_guy];
        _length = user._borrow.length;
        Borrow storage borr = user._borrow[_index];
        _token =  borr.token;
        _amount = borr.amount;
        _interest = borr.interest;
        _rate = borr.rate;
        _repay = borr.repay;
        _borrowtime = borr.borrowtime;
        _lastchange = borr.lastchange;
    }
        
    
    function repay(bytes32 _tokens, uint256 _amt) public payable returns(bool) {
        uint256 repay_amt = _tokens == 'TRX' ? msg.value : _amt;
        uint256 store_amt = _tokens == 'TRX' ? msg.value : _amt;
        
        _addrate(msg.sender);
        
        if(_tokens != 'TRX'){
            address contract_ = tokens[_tokens];
            TRC20Interface = ITRC20(contract_);
            require(TRC20Interface.transferFrom(msg.sender, address(this), _amt),"Fail");
            if (_tokens == 'RIC') {
                _safetokentransfer(_tokens, devadr, (_amt*RICFEE)/1000);
            }else{
                _safetokentransfer(_tokens, devadr, (_amt*COINFEE)/1000);
            }
        }else{
            devadr.transfer((_amt*COINFEE)/1000);
        }
        
        User storage user = _users[msg.sender];
        for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
            bytes32 token = borr.token;
            if (token == _tokens) {
                if((repay_amt+borr.repay)>(borr.amount+borr.rate)){
                    repay_amt -= (borr.amount+borr.rate) - borr.repay;
                    borr.repay = (borr.amount+borr.rate);
                }else{
                    borr.repay += repay_amt;
                    repay_amt -= repay_amt;
                }
            }
        }
        
        _changeliquidity(_tokens, store_amt, 0, 0, store_amt);
        _addreward(msg.sender);
        
        emit RepayToken(msg.sender, _tokens, store_amt);
        return true;

    }

    function _safetokentransfer(bytes32 _tokens, address _guy, uint256 _amt) internal {
        address contract_ = tokens[_tokens];
        TRC20Interface = ITRC20(contract_);
        TRC20Interface.transfer(_guy,_amt);
    }

    function pushsupply(bytes32 _tokens, uint256 _amt, address _guy) internal {

        User storage user = _users[_guy];
        user._supply.push(Supply({
            token: _tokens,
            amount: _amt,
            reward: 0,
            collateral: false,
            lastchange: block.timestamp
        }));
    }

    function pushborrow(bytes32 _tokens, uint256 _amt, address _guy) internal {
        User storage user = _users[_guy];
        user._borrow.push(Borrow({
            token: _tokens,
            amount: _amt,
            interest: getBorrowInterest(_tokens),
            rate: 0,
            repay: 0,
            borrowtime: block.timestamp,
            lastchange: block.timestamp

        }));
    }

    function _changeliquidity(bytes32 _tokens, uint256 _supplamt, uint _borrowamt,uint _rateamt, uint256 _repayamt) internal {

        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                tkid.totalsupply += _supplamt;
                tkid.totalborrow += _borrowamt;
                tkid.totalrate += _rateamt;
                tkid.totalrepay += _repayamt;
                break;
            }
        }
    }
    function _changeminliquidity(bytes32 _tokens, uint256 _supplamt, uint _borrowamt,uint _rateamt, uint256 _repayamt) internal {

        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                tkid.totalsupply -= _supplamt;
                tkid.totalborrow -= _borrowamt;
                tkid.totalrate -= _rateamt;
                tkid.totalrepay -= _repayamt;
                break;
            }
        }
    }

    function _balancetoken(address guy, bytes32 _tokens) internal returns(uint256) {
        address contract_ = tokens[_tokens];
        TRC20Interface = ITRC20(contract_);
        return (TRC20Interface.balanceOf(guy));
    }

    function changeRate(bytes32 _tokens, uint256 _supplyrate, uint _borrowrate) internal {

        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                if(_supplyrate != tkid.supplyinterest){
                tkid.supplyinterest = _supplyrate;
                tkid.borrowinterest = _borrowrate;
                emit RateChange(_tokens,_supplyrate,_borrowrate,uint256(block.timestamp));
                }
                break;
                
            }
        }
    }

    function getSupplyInterest(bytes32 _tokens) internal view returns(uint256 _supplyrate) {

        uint256 s_interest = 0;
        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                for (uint256 x = 0; x < interest_.length; x++) {
                    Interest storage intr = interest_[x];
                    
                        if (intr.token == _tokens) {
                        if(((tkid.totalsupply+tkid.totalrepay)-(tkid.totalborrow+tkid.totalrate)) > intr.maxtoken){
                            
                        }else{
                            s_interest = intr.supply;
                            break;
                        }
                      
                    }
                    
                }
                break;
            }
        }
        return (s_interest);

    }

    function getBorrowInterest(bytes32 _tokens) internal view returns(uint256 _supplyrate) {

        uint256 b_interest = 0;
        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                for (uint256 x = 0; x < interest_.length; x++) {
                    Interest storage intr = interest_[x];
                    
                        if (intr.token == _tokens) {
                        if(((tkid.totalsupply+tkid.totalrepay)-(tkid.totalborrow+tkid.totalrate)) > intr.maxtoken){
                            
                        }else{
                            b_interest = intr.borrow;
                            break;
                        }
                      
                    }
                    
                }
            }
        }
        return (b_interest);
    }

    function addrewardandrate() public onlyOwner returns(bool) {
        for (uint256 i = 0; i < userLength; i++) {
            User storage user = _user[i];
            address useraddr = user.addr;
            _addreward(useraddr);
            _addrate(useraddr);
        }
        return true;
    }

    function _addreward(address _guy) internal {

        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
                supp.reward += supp.amount  * (uint256(block.timestamp) - supp.lastchange) * getSupplyInterest(supp.token) / 365 / 86400000;
                supp.lastchange = block.timestamp;
        }

    }

    function _addrate(address _guy) internal {
        uint256 _fee = 0;
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
            if(borr.repay<(borr.amount+borr.rate)){
                if(borr.token == 'RIC'){
                    _fee = RICFEE;
                }else{
                    _fee = COINFEE;
                }
                uint256 rate_amt = (borr.amount+((borr.amount*_fee)/1000)) * (uint256(block.timestamp) - borr.lastchange) * borr.interest / 365 / 86400000;
                borr.rate += rate_amt;
                
                _changeliquidity(borr.token, 0, 0, rate_amt, 0);
                borr.lastchange = block.timestamp;
            }else{
                borr.rate = borr.repay - borr.amount; 
            }
            
        }

    }

    function changecolaterall(bytes32 _tokens) public returns(bool) {
        User storage user = _users[msg.sender];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.token == _tokens) {
                
                
                bool coll = supp.collateral ? supp.collateral = false : supp.collateral = true;
                return coll;
            }
        }
    }

    function userinfo(address _guy) public view returns(uint256 _Supply, uint256 _Borrow) {
        _Supply = _getcollateral(_guy);
        _Borrow = _getborrow(_guy);
    }

    function _getcollateral(address _guy) internal view returns(uint256) {
        uint256 coll = 0;
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.collateral) {
                bytes32 token = supp.token;
                uint256 dec = uint256(_getdecimals(token));
                uint256 price = getPrice(token);
                uint256 InUSD = ((supp.amount + supp.reward)* price)/ (10 ** dec);
                coll += InUSD;
            }
        }
        return coll;
    }
    function _gettokencollateral(address _guy,bytes32 _tokens) internal view returns(uint256) {
        uint256 coll = 0;
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.collateral) {
                if(supp.token == _tokens){
                bytes32 token = supp.token;
                uint256 dec = uint256(_getdecimals(token));
                uint256 price = getPrice(token);
                uint256 InUSD = ((supp.amount + supp.reward)* price)/ (10 ** dec);
                coll += InUSD;
                break;
                }
            }
        }
        return coll;
    }


    function _getborrow(address _guy) internal view returns(uint256) {
        uint256 bor_amt = 0;
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
            bytes32 token = borr.token;
            uint256 dec = uint256(_getdecimals(token));
            uint256 price = getPrice(token);
            uint256 InUSD = (((borr.amount + borr.rate) - borr.repay) * price ) / (10 ** dec);
            bor_amt += InUSD;
        }
        return bor_amt;
    }

   function withdraw(bytes32 _tokens,uint256 _amt)public returns(bool){
        _addreward(msg.sender);
        uint256 dec = uint256(_getdecimals(_tokens));
        uint256 price = getPrice(_tokens);
        uint256 amt_inUSD = (_amt * price) / (10 ** dec);
        uint256 collateral_amt = _gettokencollateral(msg.sender,_tokens);
        uint256 borrow_amt = _getborrow(msg.sender);
        require(borrow_amt == 0, "Balance lock, until borrow amount was payed.");
        require(collateral_amt >= amt_inUSD, "insufficient balance.");
        
        if (_tokens == 'TRX') {
            msg.sender.transfer(_amt);
        } else {
            if (_tokens == 'RIC') {
                _safetokentransfer(_tokens, msg.sender, _amt);
            }else{
                _safetokentransfer(_tokens, msg.sender, _amt);
            }
        }
        
        User storage user = _users[msg.sender];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.token == _tokens) {
                supp.amount -= _amt;
            }
        }
        
        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                tkid.totalsupply -= _amt;
                   
            }
        }
        return true;
       
   }

    function poolinfo() public view returns(uint256 _Supply, uint256 _Borrow, uint256 _Rate, uint256 _RepayWithRate) {

        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            bytes32 token = tkid.tokenbyte;
            tkid.totalsupply;
            tkid.totalborrow;
            uint256 dec = uint256(_getdecimals(token));
            uint256 price = getPrice(token);
            _Supply += (tkid.totalsupply * price ) / (10 ** dec);
            _Borrow += (tkid.totalborrow * price ) / (10 ** dec);
            _Rate += (tkid.totalrate * price ) / (10 ** dec);
            _RepayWithRate += (tkid.totalrepay * price ) / (10 ** dec);
        }
    }

    function _getdecimals(bytes32 _tokens) internal view returns(uint8) {

        for (uint256 i = 0; i < _tokenID.length; i++) {
            IDToken storage tkid = _tokenID[i];
            if (tkid.tokenbyte == _tokens) {
                return tkid.decimals;
            }
        }

    }

    function _checkreward(bytes32 _tokens, address _guy) internal view returns(uint256) {
        uint256 userreward = 0;

        uint256 interest = getSupplyInterest(_tokens);
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.token == _tokens) {
                uint256 reward = supp.amount + supp.reward;
                userreward = reward * (uint256(block.timestamp) - supp.lastchange) * interest / 365 / 864000000;
                break;
            }
        }

        return userreward;
    }
    function _checkrate(bytes32 _tokens, address _guy) internal view returns(uint256) {
        uint256 userrate = 0;
        User storage user = _users[_guy];
        for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
            if (borr.token == _tokens) {
                userrate +=borr.amount * (uint256(block.timestamp) - borr.lastchange) * borr.interest / 365 / 864000000;
            }
        }

        return userrate;
    }

    function usertokeninfo(bytes32 _tokens, address _guy) public view returns(
        bytes32 token,
        uint256 supplyamount,
        uint256 reward,
        bool collateral,
        uint256 borrowamount,
        uint256 rateamount,
        uint256 repayamount) {

        User storage user = _users[_guy];

        for (uint256 i = 0; i < user._supply.length; i++) {
            Supply storage supp = user._supply[i];
            if (supp.token == _tokens) {
                token = _tokens;
                supplyamount = supp.amount;
                reward = _checkreward(_tokens, _guy);
                collateral = supp.collateral;
                break;
            }
        }
        for (uint256 i = 0; i < user._borrow.length; i++) {
            Borrow storage borr = user._borrow[i];
            if (borr.token == _tokens) {
                borrowamount += borr.amount;
                rateamount = _checkrate(_tokens, _guy);
                repayamount += borr.repay;
            }
        }


    }


}