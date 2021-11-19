// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Token.sol";
import "./CRUD.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";


contract Vault is Initializable, OwnableUpgradeable, UUPSUpgradeable, IERC721Receiver {
    /* 
    Right now there are 2 stages of funding process:
    */ 
    address public initiator;  // Offchain initiator
    // cбор, сбор закончен, сбор отменен
    enum Stages{ IN_PROGRESS, FULL, LOCKED, ONSALE, SOLD }

    struct vaultStorage {
        mapping(address => bool) assetLocked;
        address[] erc20;  // Locked ERC20
    }

    struct Erc721Storage {
            address nftContract;
            address seller;
            uint256 tokenId;
            bytes data;
            uint price;
            address buyer;
            uint balanceAfter;
        }

    address[] users;

    mapping(address => uint) userToEth;
    mapping(address => uint) stakes;

    vaultStorage vault;
    Erc721Storage erc721;

    Token vaultToken;
    uint total;
    bool private priceSet;

    Stages public stage = Stages.IN_PROGRESS;

    event NewDeposit(address vaultAddr, address sender, uint deposit);
    event TransferToOracle(address indexed vaultAddr, address indexed oracleAddr, uint amount);

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    
    modifier transitionAfter() {
        _;
        nextStage();
    }

    modifier onlyInitiator {require(msg.sender == initiator, "To run this method you need to be an initiator of the contract."); _;}

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setInitiator(address _new_initiator) public onlyOwner {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }

    function initialize (string memory _name, 
                        string memory _ticker, 
                        uint _shares_amount) public initializer {
        // Tokens are minted automatically after the contract initialization.
        __Ownable_init_unchained();
        vaultToken = new Token();
        vaultToken.initialize(
                _name,
                _ticker,
                _shares_amount,  // ToDo initialize: We should discuss the amount of minted shares.
                address(this));
        // Get token address.
        address tokenAddress = address(vaultToken); 
        //Add asset to the list of all assets.
        addErc20Asset(tokenAddress);
    }

    function recieveDeposit(address _user) public payable atStage(Stages.IN_PROGRESS) {
        if (userToEth[_user] == 0) {
            // Add the user address to the dynamic array of users.
            users.push(_user);
        }
        // Update user stats.
        total += msg.value; 
        userToEth[_user] += msg.value; 
        emit NewDeposit(address(this), _user, msg.value);
    } 

    /* _________GETTERS_________
    */

    function getTokenAddress() public view returns(address){
        return address(vaultToken);
    }

    function getTokenName() public view returns(string memory) {
        return vaultToken.name();
    }

    function getTokenTicker() public view returns(string memory) {
        return vaultToken.symbol();
    }
    
    function getUserDeposit(address _user) public view returns(uint) {
        return userToEth[_user];
    }
    
    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function getStake(address _user) public view atStage(Stages.FULL) returns (uint){
        return stakes[_user];
    }

    function getErc721Price() public view atStage(Stages.ONSALE) returns (uint){
        return erc721.price;
    }

    function getErc721Address() public view atStage(Stages.ONSALE) returns (address){
        return erc721.nftContract;
    }


    /* __________________________
    */

    function stake(uint _amount) public atStage(Stages.FULL) {
        /*
        */              
        if (vaultToken.allowance(msg.sender, address(this)) < _amount) {
            vaultToken.approve(address(this), _amount);
        }
        vaultToken.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] += _amount;
    }

    function autoStake(uint _amount, address _user) public atStage(Stages.FULL) {
        //vaultToken.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_user] += _amount;
    }

    function claimTokens(uint _amount, address _user) public atStage(Stages.FULL) {  // 50
        require(msg.sender == _user);
        uint userStake = stakes[_user];  // 2
        if (userStake < _amount) {  // 2*50 < 50
            vaultToken.transfer(_user, userStake);
        } else {
            vaultToken.transfer(_user, _amount);
            }
    }

    function addErc20Asset(address _assetAddress) public onlyOwner {  
        require(vault.assetLocked[_assetAddress] == false, "This asset is already locked");
        vault.erc20.push(_assetAddress);
        vault.assetLocked[_assetAddress] = true;
    }
    
    function getErc20Assets() public view atStage(Stages.FULL) returns(address[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this vault.
        */
        return vault.erc20;
    }
    
    function distributeTokens() public atStage(Stages.FULL) onlyOwner {
        /*
        */
        uint k = vaultToken.totalSupply() / total;
        vaultToken.approve(address(this), vaultToken.totalSupply());
        for (uint i = 0; i < users.length; i++) {
            address recipient = users[i];
            autoStake(userToEth[recipient]*k, recipient);
        }
    }

    function withdrawFinal() public atStage(Stages.SOLD) {
        require(userToEth[msg.sender] > 0, "This user is not a participant.");
        uint factor = total / userToEth[msg.sender];
        uint amount = erc721.balanceAfter / factor;
        payable(msg.sender).transfer(amount);
    }

    function withdrawDeposit(uint _amount) public atStage(Stages.IN_PROGRESS) {
        require(userToEth[msg.sender] > 0, "The user has no deposit");
        require(userToEth[msg.sender] >= _amount, "Not enough deposit on user's balance");
        userToEth[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    } 

    function transferToOracle(uint _amount) public onlyInitiator {
        payable(initiator).transfer(_amount);
        emit TransferToOracle(address(this), initiator, _amount);
        
    }

    function sellERC721(address _to) public atStage(Stages.ONSALE) transitionAfter payable {
        require(erc721.price==msg.value, "Send the accurate price of the asset!");
        require(priceSet==true, "The price is not set!");
        ERC721 nftContract = ERC721(erc721.nftContract);
        nftContract.safeTransferFrom(address(this), _to, 1);
        erc721.buyer = _to;
        erc721.balanceAfter = getBalance()+msg.value;
    }

   function setTokenPrice(uint256 _price) public onlyInitiator atStage(Stages.ONSALE) {
       erc721.price = _price;
       priceSet = true;
   }

    function nextStage() public onlyInitiator {
        stage = Stages(uint(stage) + 1);
    }

    function onERC721Received(address operator,
                              address from,
                              uint256 tokenId,
                              bytes calldata data) public atStage(Stages.FULL) transitionAfter override returns (bytes4) {
        erc721.nftContract = msg.sender;
        erc721.seller = from;
        erc721.tokenId = tokenId;
        erc721.data = data;
        return this.onERC721Received.selector;
    }
}