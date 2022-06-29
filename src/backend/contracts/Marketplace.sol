// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {

    //State Variables
    address payable public immutable feeAccount; //the account that receives the fees
    uint public immutable feePercent;  //the fee percentage on sales
    uint public itemCount;

    //Struct to store NFT Item information
    struct Item{
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    //Define Offered event
    event Offered(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );

    //Define Bought event
    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    //Mapping to hold NFT items
    mapping(uint => Item) public items;

    constructor (uint _feePercent){
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function makeItem(IERC721 _nft, uint _tokenId, uint _price) external nonReentrant {

        require(_price > 0, "Price must be greater than zero");

        //incrent itemCount
        itemCount ++;

        //Transfer NFT
        _nft.transferFrom(msg.sender, address(this), _tokenId);

        //Add new item to items mapping
        items[itemCount] = Item (
            itemCount,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );

        //Emit Offered Event
        emit Offered(
            itemCount,
            address(_nft),
            _tokenId,
            _price,
            msg.sender
        );
    }

    function purchaseItem(uint _itemId) external payable nonReentrant {

        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require(_itemId > 0 && _itemId <= itemCount, "Item Doesn't Exist");
        require(msg.value >= _totalPrice, "Not Enough Ether to Cover Item Price and Market Fee");
        require(!item.sold, "Item Already Sold");

        //Pay the Seller
        item.seller.transfer(item.price);
        feeAccount.transfer(_totalPrice - item.price);

        //Update the Item as sold
        item.sold = true;

        //Transfer the NFT to the Buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);

        //Emit Bought Event
        emit Bought(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );

    }

    function getTotalPrice(uint _itemId) view public returns(uint) {
       return(items[_itemId].price*(100 + feePercent)/100);
    }
}