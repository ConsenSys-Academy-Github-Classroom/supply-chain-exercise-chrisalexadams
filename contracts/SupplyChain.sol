// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount = 0;
  mapping (uint => Item) items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  modifier isOwner {
    require(msg.sender == owner, "Not the owner");
    _;
  }

  modifier verifyCaller (address _address) {
    require(msg.sender == _address, "Not the sender");
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "Not enough funds");
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale && items[_sku].price > 0, "Item not for sale");
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold, "Item not sold");
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped, "Item not shipped");
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received, "Item not received");
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
      items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });

    skuCount ++;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    uint _price = items[sku].price;
    items[sku].seller.transfer(_price);

    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;

    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;

    emit LogReceived(sku);
  }

   function fetchItem(uint _sku) public view
     returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
   {
     name = items[_sku].name;
     sku = items[_sku].sku;
     price = items[_sku].price;
     state = uint(items[_sku].state);
     seller = items[_sku].seller;
     buyer = items[_sku].buyer;
     return (name, sku, price, state, seller, buyer);
   }
}
