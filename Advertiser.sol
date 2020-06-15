pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Ad.sol";
import "./Library.sol";

contract Advertiser{
    Ad [] ads;
    
    function addAdToList(address _ad) public {
        ads.push(Ad(_ad));
    }

}