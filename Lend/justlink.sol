pragma solidity ^0.5.0;

import "./token/Ownable.sol";

interface AggregatorInterface  {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract PriceConsumer is Ownable {
    
    
    AggregatorInterface internal priceFeedTRX;
    AggregatorInterface internal priceFeedBTC;
    AggregatorInterface internal priceFeedETH;
    AggregatorInterface internal priceFeedUSDT;

    uint256 internal retprice = 0;
   
     constructor(address _TRX,address _BTC,address _ETH,address _USDT)public{
         priceFeedTRX = AggregatorInterface(_TRX);
         priceFeedBTC = AggregatorInterface(_BTC);
         priceFeedETH = AggregatorInterface(_ETH);
         priceFeedUSDT = AggregatorInterface(_USDT);
     }
     
    function updatePrice(uint256 _uint)public onlyOwner returns(bool){
        retprice = _uint;
    }
    function getPrice(bytes32 _pair) public view returns (uint256) {
        uint256 ret = 0;
        if(_pair == 'TRX'){
            require(priceFeedTRX.latestTimestamp() > 0, "Round not complete");
            ret = uint256(priceFeedTRX.latestAnswer()); 
        }else if(_pair == 'BTC'){
            require(priceFeedBTC.latestTimestamp() > 0, "Round not complete");
            ret = uint256(priceFeedBTC.latestAnswer()); 
        }else if(_pair == 'ETH'){
            require(priceFeedETH.latestTimestamp() > 0, "Round not complete");
            ret = uint256(priceFeedETH.latestAnswer()); 
        }else if(_pair == 'USDT'){
            require(priceFeedUSDT.latestTimestamp() > 0, "Round not complete");
            ret = uint256(priceFeedUSDT.latestAnswer()); 
        }else if(_pair == 'RIC'){
            require(priceFeedUSDT.latestTimestamp() > 0, "Round not complete");
            ret = uint256(priceFeedUSDT.latestAnswer()) * 929 / 1000; 
        }else if(_pair == 'RET'){
           ret = retprice; 
        }
        
        return ret;
        
    }
}