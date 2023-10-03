// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PixelContract {

    address payable public owner; // This will store your address

    constructor() {
        owner = payable(msg.sender); // Set the contract deployer as the owner
    }
    
    struct Pixel {
        uint32 id;
        uint32 colorValue;
        address owner;
        string nftLink; // Renamed from nftAddress to nftLink and changed type to string
    }

    mapping(uint32 => Pixel) public pixels;
    Pixel[3] public luckyPixels; // Storing entire Pixel structures for the lucky owners
    Pixel[3] public luckyNftSoldPixels; // Storing entire Pixel structures for the lucky NFT sold owners

    uint32 public totalSoldPixels = 0;
    uint256 public constant PIXEL_PRICE = 0.01 ether;

    event PixelOwnershipChanged(uint32 indexed id, uint32 colorValue, address indexed newOwner, string nftLink);

    modifier onlyOnceLuckyPixels() {
        require(luckyPixels[0].owner == address(0), "Lucky pixels have already been set.");
        _;
    }

    modifier onlyOnceLuckyNftSoldPixels() {
        require(luckyNftSoldPixels[0].owner == address(0), "Lucky NFT sold pixels have already been set.");
        _;
    }

    modifier allPixelsSold() {
        require(totalSoldPixels == 1024, "All pixels have not been sold yet.");
        _;
    }

    function setPixelOwnershipById(uint32 id, uint32 colorValue, string memory nftLink) public payable {
        require(pixels[id].owner == address(0), "Pixel already owned!");
        require(msg.value >= PIXEL_PRICE, "Payment value is below the pixel price!");

        // Transfer the received Ether directly to the owner's address
        owner.transfer(msg.value);

        pixels[id] = Pixel({
            id: id,
            colorValue: colorValue,
            owner: msg.sender,
            nftLink: nftLink
        });
        totalSoldPixels++;

        emit PixelOwnershipChanged(id, colorValue, msg.sender, nftLink);
    }

    function getPixelOwnershipById(uint32 id) public view returns(uint32, uint32, address, string memory) {
        Pixel memory pixel = pixels[id];
        return (pixel.id, pixel.colorValue, pixel.owner, pixel.nftLink);
    }

    function getAllPixels() public view returns(Pixel[] memory) {
        Pixel[] memory allPixels = new Pixel[](1024);
        for (uint32 i = 0; i < 1024; i++) {
            allPixels[i] = pixels[i];
        }
        return allPixels;
    }

    function setLuckyPixels() public onlyOnceLuckyPixels allPixelsSold {
        // Simple random selection; More secure randomness is advised for production
        for (uint i = 0; i < 3; i++) {
            uint32 randomPixelId = uint32(uint(keccak256(abi.encodePacked(block.timestamp, i))) % 1024);
            luckyPixels[i] = pixels[randomPixelId];
        }
    }

    function setLuckyNftSoldPixels() public onlyOnceLuckyNftSoldPixels allPixelsSold {
        // Ensure luckyPixels have been set
        require(luckyPixels[0].owner != address(0), "Lucky pixels must be set first.");

        for (uint i = 0; i < 3; i++) {
            uint32 randomPixelId;
            do {
                randomPixelId = uint32(uint(keccak256(abi.encodePacked(block.timestamp, i))) % 1024);
            } while (_isInLuckyPixels(randomPixelId));

            luckyNftSoldPixels[i] = pixels[randomPixelId];
        }
    }

    function _isInLuckyPixels(uint32 pixelId) internal view returns(bool) {
        for (uint i = 0; i < 3; i++) {
            if (luckyPixels[i].id == pixelId) {
                return true;
            }
        }
        return false;
    }
}
