pragma solidity ^0.5.12;  
  
import "./ITRC20.sol";
import "./Ownable.sol";  
  
contract swap is Ownable {  
  
 address internal RET = address(0x0);
 address internal RET2 = address(0x0);
  
 
  
  ITRC20 internal TRC20Interface;  
  
  event Swap(address indexed from_, uint256 amount_);

 function SwapRET(uint256 _amt) public returns(bool) {
     
     TRC20Interface = ITRC20(RET);
     
     uint256 allowbal = TRC20Interface.allowance(msg.sender,address(this));
     
     require(_amt <= allowbal ,"Msg :: Please approve token first");
     
     TRC20Interface.transferFrom(msg.sender,address(this), _amt);
     
     _swap(msg.sender,_amt);
     
     emit Swap(msg.sender,_amt);
     return (true);
        
 }
 
constructor( address RET_, address RET2_) public { 
      RET = RET_;
      RET2 = RET2_;
 } 

function _swap(address guy, uint256 amount) internal {
    
     TRC20Interface = ITRC20(RET2);
     TRC20Interface.transferFrom(owner(),guy,amount);
     
}

}