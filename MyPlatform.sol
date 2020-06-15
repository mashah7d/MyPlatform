pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SortedList.sol";
import "./DateTime.sol";
import "./Ad.sol";
import "./Library.sol";

contract MyPlatform {
    // mapping (address => Advertiser) private advertisers;
    mapping (address => Ad []) public ads;
    
    //****List of all participants
    mapping (address => Library.Participant) participantsList;
    
    //****Participants sorted by score in each category
    mapping (string => SortedList) sortedParticipantsByCategoryScores;
    
    uint initialNumberOfAdRecievers = 200;
    uint treeHeightLimit = 5;
    
    uint public test;
    
    modifier costs(uint price) {
        require(msg.sender.balance > price);
        _;
    }
    
    modifier advertiserHasEnoughDeposit(uint _budget){
        require(msg.value > _budget,"Not enough Ether provided.");
        _;
    }
    
    modifier advertiseEndDateHasReached(Library.SimpleDate memory _date){
        require(DateTime.intDiffDays(now, DateTime.timestampFromDate(_date.year, _date.month, _date.day))>0, "Advertise is still in progress!");
        _;
    }
    
    modifier notDuplicateRecipient (address _ad, address _recipient){
        require(Ad(_ad).fatherExists(_recipient), "This user already has received this advertise");
        _;
    }
    
    modifier recipientRegionMatches(address _ad, address _recipient){
        require(keccak256(abi.encodePacked(Ad(_ad).getRegion())) == keccak256(abi.encodePacked(participantsList[_recipient].region)));
        _;
    }
    
    function testFunction () public {
        test = (test + 1)*3/10;
    }
    
    //advertiser orders an ad having a category, link, start and end date
    //the value of the function call will be the amount of advertiser budget
    //for the ad plus the amount of gas needed for system calculation fees
    //like conversion rate fees
    function orderAd(string memory _category, string memory _geographicalArea, string memory _link,
                    uint startYear, uint startMonth, uint startDay,
                    uint endYear, uint endMonth, uint endDay) public payable {
        //require(msg.value > )
        //value depending on range of ad//////days counted
        
        Library.SimpleDate memory _startDate = Library.SimpleDate({year:startYear, month:startMonth, day:startDay});
        Library.SimpleDate memory _endDate = Library.SimpleDate({year:endYear, month:endMonth, day:endDay});
        
        uint _budget = msg.value;
        
        Ad ad = new Ad(_category, _geographicalArea, _link, _budget, _startDate, _endDate, initialNumberOfAdRecievers);
        
        ads[msg.sender].push(ad);
        
        // initiateAdvertising(msg.sender);
    }
    
    function updateParticipantCategories(string [] memory _categories) private {
        participantsList[msg.sender].categories = _categories;
    }
    
    function sendAd(address _ad, address _recipient, string memory _adLink) public notDuplicateRecipient(_ad, _recipient) recipientRegionMatches(_ad, _recipient) {
        //add referral to ad referral list
        Ad(_ad).addReferralToList(msg.sender, _recipient);
        
        //set recipient sender address
        //participantsList[_recipient].adsData[Ad(_ad)].sender = msg.sender;
        
        //add participant to list of forwards in participantAdData
        //participantsList[msg.sender].adsData[Ad(_ad)].forwarded.push(_recipient);
        
        //increase number of indirect referrals
        increaseNumOfIndirectReferrals(_ad, msg.sender);
        
        //add ad to participant ad list
        if(!participantsList[msg.sender].adsData[Ad(_ad)].hasValue) {
            participantsList[msg.sender].adsParticipatedByCategory[Ad(_ad).getCategory()].push(Ad(_ad));
            participantsList[msg.sender].adsData[Ad(_ad)].hasValue = true;
        }
    }
    
    //increase sender point and its fathers till the tree height limit
    function increaseNumOfIndirectReferrals(address _ad, address _sender) private {
        uint level;
        address child;
        address father;
        child = _sender;
        while(level<treeHeightLimit){
            father = Ad(_ad).getFather(child);
            participantsList[father].adsData[Ad(_ad)].numOfIndirectReferrals++;
            level++;
        }
    }
    
    //set ad conversion of a recipient in the sender conversion mapping in a single ad
    //function caller will be the contract or our platform and the gas will be payed from 
    //the advertiser budget
    function setAdConversionToTrue(address _sender, address _ad, address _receiver) public {
        require(!participantsList[_sender].adsData[Ad(_ad)].recipientConversions[_receiver]);
        
        participantsList[_sender].adsData[Ad(_ad)].numOfConversion++;
        Ad(_ad).increaseTotalConversionNumber();
        participantsList[_sender].adsData[Ad(_ad)].recipientConversions[_receiver] = true;
        updateParticipantPoint(_sender, _ad);
    }
    
    function updateScoreInCategoryOnAdFinish(address _participant, address _ad) public {
        uint score = sortedParticipantsByCategoryScores[Ad(_ad).getCategory()].scores(_participant);
        //number of ads participant participated in the category of the mentioned ad
        uint num = participantsList[_participant].adsParticipatedByCategory[Ad(_ad).getCategory()].length;
        score = (score*num + participantsList[_participant].adsData[Ad(_ad)].totalPoint/Ad(_ad).getNumberOfDays())/(num+1);
    }
    
    function updateScoreInCategory(address _participant, string memory _subject, uint _score) public {
        sortedParticipantsByCategoryScores[_subject].updateScore(_participant, _score);
    }

    function getScoreInSubject(string calldata _subject) view external returns(uint) {
        return sortedParticipantsByCategoryScores[_subject].scores(msg.sender);
    }

    //return ad results
    function getAdResults(address _ad) public advertiseEndDateHasReached(Ad(_ad).getEndDate()) returns (uint _numOfAdRecievers, uint _numOfConversions) {
        _numOfAdRecievers = Ad(_ad).getNumOfAdRecievers();
        _numOfConversions = Ad(_ad).getNumOfAdConversions();
    }
    
    //claim ad rewards and receive reward of the selected ad by participant
    function claimAdRewards(address _ad) public {
        uint _reward = calculateParticipantAdReward(msg.sender, _ad);
        msg.sender.transfer(_reward);
    }
    
    function calculateParticipantAdReward(address _participant, address _ad) internal returns (uint _reward) {
        _reward = (participantsList[_participant].adsData[Ad(_ad)].totalPoint / 
                  ((Ad(_ad).getNumOfAdRecievers()*30)/100)+((Ad(_ad).getNumOfAdConversions()*70)/100))*Ad(_ad).getBudget();
    }
    
    //calculation of participant point on a single ad
    function updateParticipantPoint(address _participant, address _ad) public advertiseEndDateHasReached(Ad(_ad).getEndDate()) returns (uint _point) {
        // (Ad(_ad).getNumOfDirectForwards(msg.sender)*10)/100+
        _point = (participantsList[msg.sender].adsData[Ad(_ad)].numOfIndirectReferrals*30)/100+
                 (participantsList[msg.sender].adsData[Ad(_ad)].numOfConversion*70)/100;
    }
    
    // function activateAd(address _advertiser) private{
    //     ads[_advertiser].setActive(true);
    // }

    
    // function initiationAdParticipants(string memory _subject) private returns (Participant [] memory){
    //     Participant[] memory _participantsNeeded;
    //     //push participants to array
    //     for(uint i=0; i<participants.length; i++){
            
    //     }
        
    //     return _participantsNeeded;
    // }


    // int public timeTesting;
    // function testTime(uint year, uint month, uint day) public returns (int timestamp){
    //     timestamp = DateTime.intDiffDays(now, DateTime.timestampFromDate(year,month,day));
    //     timeTesting = timestamp;
    // }

    // function initiateAdvertising(address _advertiser) private{
    //     //check when the start date reaches and start ad
    //     Library.SimpleDate memory _startDate = ads[_advertiser].getStartDate();
    //     Library.SimpleDate memory _endDate = ads[_advertiser].getEndDate();

    //     // while(DateTime.intDiffDays(now, DateTime.timestampFromDate(_startDate.year,_startDate.month,_startDate.day))<0 
    //     //     && DateTime.intDiffDays(now, DateTime.timestampFromDate(_endDate.year,_endDate.month,_endDate.day))>0 ){
    //     //         //needs to be activated only once and also deactivated at the end
    //     //         activateAd(_advertiser);
    //     // }
    //     //DEACTIVATE ad
    // }
}

// contract Participant {
//     bool viewed;
//     bool forwarded;
//     uint forwardingScore;
    
//     //This mapping shows the participants score in each ad subject
//     mapping (string => uint) subjectScore;
// }