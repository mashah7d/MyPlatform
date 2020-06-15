pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Ad.sol";

library Library {
    
    /***Data struct***/
    struct data {
        uint val;
        bool isValue;
    }
   
    /****Date struct****/
    struct SimpleDate{
        uint year;
        uint month;
        uint day;
    }
    
    /****Ad Participant struct****/
    struct participantAdData{
        // address sender;
        uint numOfIndirectReferrals;
        uint numOfConversion;
        uint totalPoint;
        bool hasValue;
        mapping (address => bool) recipientConversions;
        //address[] forwarded;
        uint height;
    }
    
    /****Participant struct****/
    struct Participant{
        mapping (Ad => participantAdData) adsData;
        string [] categories;
        string region;
        mapping (string => Ad []) adsParticipatedByCategory;
    }
    
}