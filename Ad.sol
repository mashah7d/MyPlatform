pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Advertiser.sol";
import "./Library.sol";
import "./DateTime.sol";

contract Ad {
    mapping (address => address[]) public referrals;
    mapping (address => address) public recipients;
    //mapping (address => Library.participantAdData) public adParticipantsList;

    Advertiser private advertiser;
    string private category;
    string private region;
    string private link;
    uint private budget;
    // bool private active;
    //start and end date handling
    Library.SimpleDate startDate;
    Library.SimpleDate endDate;
    
    uint numOfAdRecievers;
    uint numOfConversions;

    constructor(string memory _category, string memory _region, string memory _link, uint _budget, Library.SimpleDate memory _startDate, Library.SimpleDate memory _endDate, uint _initialNumberOfAdRecievers) public{
        category = _category;
        link = _link;
        budget = _budget;
        startDate = _startDate;
        endDate = _endDate;
        numOfAdRecievers = _initialNumberOfAdRecievers;
        region = _region;
    }
    
    function getCategory() public view returns (string memory _category) {
        _category = category;
    }
    
    function getStartDate() public view returns (Library.SimpleDate memory _startDate){
        _startDate = startDate;
    }
    
    function getEndDate() public returns (Library.SimpleDate memory _endDate){
        _endDate = endDate;
    }
    
    function getNumberOfDays() public view returns (uint _days) {
        _days = DateTime.getDaysBetween(startDate.year, startDate.month, startDate.day, endDate.year, endDate.month, endDate.day);
    }
    
    function getRegion() public view returns (string memory _region) {
        _region = region;
    }
    
    function getFather(address _child) public view returns (address _father) {
        _father = recipients[_child];
    }
    
    function getNumOfAdRecievers() public view returns (uint _num) {
        _num = numOfAdRecievers;
    }
    
    function getNumOfAdConversions() public view returns (uint _num) {
        _num = numOfConversions;
    }
    
    function getBudget() public view returns (uint _budget) {
        return budget;    
    }
    
    function addReferralToList(address _sender, address _receiver) public {
        numOfAdRecievers++;
        referrals[_sender].push(_receiver);
        recipients[_receiver] = _sender;
    }
    
    function fatherExists(address _receiver) public view returns (bool _exists) {
        if(recipients[_receiver]!=address(0))
            _exists = true;
        return _exists;
    }
    
    function getNumOfDirectForwards(address _participant) public returns (uint _num) {
        _num = referrals[_participant].length;
    }
    
    function increaseTotalConversionNumber() public {
        numOfConversions++;
    }
    
    function calculateAdRewards() public returns (uint){
        //calc ad rewards
        uint reward = 0;
        return reward;
    }

}