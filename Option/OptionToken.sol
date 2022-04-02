// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {ERC721} from "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "./@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OptionToken is Ownable, ERC721, IERC721Receiver {

    event Start(string log, uint price);
    event Buy(address indexed sender);
    event End();
    event Cash();

    uint public balance;

    uint public nftOptionId;
    uint public price;
    uint public day;
    address payable public seller;
    address payable public buyer;
    mapping(address => bool) public buyerCash;
    bool public started;
    bool public ended;
    uint public endAt;


    // 86400 / 以太坊平均出块速度15s
    uint constant ONEDAY = 5760;

    constructor(uint _tokenId) ERC721("ETH_OPTION", "EOP") {    
        seller = payable(msg.sender);
        _mint(seller, _tokenId);
        nftOptionId = _tokenId;
    }

    // 发行期权
    function issue(
        uint _day,
        uint _price
    ) 
        payable 
        public 
        onlyOwner
    {
        require(!started, "Already started");
        require(msg.sender == seller, "not seller");
        require(msg.value == _price, "is not right ETH");

        price = _price;
        day = _day;
        balance += msg.value;
        started = true;
        endAt = block.number + _day*ONEDAY;

        approve(address(this), nftOptionId);
        safeTransferFrom(msg.sender, address(this), nftOptionId);
        
        emit Start("Option start with ETH(Wei):", _price);
    }

    //购买
    function buy() public payable {
        require(started, "not started");
        require(block.number < endAt, "ended");
        require(msg.value == price, "Not enough ETH");

        balance += msg.value;
        buyer = payable(msg.sender);
        buyerCash[buyer] = false;

        IERC721(this).safeTransferFrom(address(this), msg.sender, nftOptionId);
        
        emit Buy(msg.sender);
    }

    // 行权
    function cash() public payable {
        require(started, "not started");
        require(block.number >= endAt, "not the Time");
        require(!ended, "ended");
        require(buyer == msg.sender, "Not for you");
        require(buyerCash[buyer] == false, "You have cashed");

        buyerCash[buyer] = true;
        ended = true;
        started = false;
        balance -= price;

        (bool success, ) = payable(msg.sender).call{value: price}("");
        require(success, "Transfer Error");
        
        emit Cash();
    }

    // 销毁
    function end() public payable onlyOwner {
        require(block.number >= endAt + 3*ONEDAY, "not ended");
        emit End();

        selfdestruct(seller);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) 
        external
        override 
        returns (bytes4)
    {
        return bytes4(keccak256(bytes("onERC721Received(address,address,uint256,bytes)")));
    }

}