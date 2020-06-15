pragma solidity >=0.4.0 <0.7.0;

contract SortedList{

  mapping(address => uint256) public scores;
  mapping(address => address) _nextItems;
  uint256 public listSize;
  address constant HEADER = address(1);

  constructor() public {
    _nextItems[HEADER] = HEADER;
  }

  function addItem(address item, uint256 score) public {
    require(_nextItems[item] == address(0));
    address index = _findIndex(score);
    scores[item] = score;
    _nextItems[item] = _nextItems[index];
    _nextItems[index] = item;
    listSize++;
  }

  function increaseScore(address item, uint256 score) public {
    updateScore(item, scores[item] + score);
  }

  function reduceScore(address item, uint256 score) public {
    updateScore(item, scores[item] - score);
  }

  function updateScore(address item, uint256 newScore) public {
    require(_nextItems[item] != address(0));
    address prevItem = _findPrevItem(item);
    address nextItem = _nextItems[item];
    if(_verifyIndex(prevItem, newScore, nextItem)){
      scores[item] = newScore;
    } else {
      removeItem(item);
      addItem(item, newScore);
    }
  }

  function removeItem(address item) public {
    require(_nextItems[item] != address(0));
    address prevItem = _findPrevItem(item);
    _nextItems[prevItem] = _nextItems[item];
    _nextItems[item] = address(0);
    scores[item] = 0;
    listSize--;
  }

  function getTop(uint256 k) public view returns(address[] memory) {
    require(k <= listSize);
    address[] memory itemLists = new address[](k);
    address currentAddress = _nextItems[HEADER];
    for(uint256 i = 0; i < k; ++i) {
      itemLists[i] = currentAddress;
      currentAddress = _nextItems[currentAddress];
    }
    return itemLists;
  }


  function _verifyIndex(address prevItem, uint256 newValue, address nextItem)
    internal
    view
    returns(bool)
  {
    return (prevItem == HEADER || scores[prevItem] >= newValue) && 
           (nextItem == HEADER || newValue > scores[nextItem]);
  }

  function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = HEADER;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextItems[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextItems[candidateAddress];
    }
  }

  function _isPrevItem(address item, address prevItem) internal view returns(bool) {
    return _nextItems[prevItem] == item;
  }

  function _findPrevItem(address item) internal view returns(address) {
    address currentAddress = HEADER;
    while(_nextItems[currentAddress] != HEADER) {
      if(_isPrevItem(item, currentAddress))
        return currentAddress;
      currentAddress = _nextItems[currentAddress];
    }
    return address(0);
  }
} 