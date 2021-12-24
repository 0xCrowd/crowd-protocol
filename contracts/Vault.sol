// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Token.sol";
import "./CRUD.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";


contract Vault is Initializable, OwnableUpgradeable, UUPSUpgradeable, IERC721Receiver, IERC1155Receiver {
    /* 
    Right now there are 2 stages of funding process:
    */ 
    address public initiator;  // Offchain initiator
    // cбор, сбор закончен, сбор отменен

    struct vaultStorage {
        mapping(address => bool) assetLocked;
        address[] erc20;  // Locked ERC20
    }

    struct TokenStorage {
            address tokenAddr;
            address seller;
            uint256 tokenId;
            uint8 tokenType;
            address buyer;
            uint balanceAfter;
        }

    address[] users;

    mapping(address => uint) userToEth;
    mapping(address => uint) stakes;

    vaultStorage vault;
    TokenStorage tokenStorage;

    Token vaultToken;
    uint total;

    event NewDeposit(address vaultAddr, address sender, uint deposit);
    event TransferToOracle(address indexed vaultAddr, address indexed oracleAddr, uint amount);

    modifier onlyInitiator {require(msg.sender == initiator, "To run this method you need to be an initiator of the contract."); _;}

    /*
    ___________STAGE CONTROLLING OPERATIONS________________
    */

    enum Stages{ IN_PROGRESS, FULL, LOCKED, ONSALE, SOLD }

    Stages public stage = Stages.IN_PROGRESS;

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    
    modifier transitionAfter() {
        _;
        _nextStage();
    }

    function nextStage() public onlyInitiator {
        stage = Stages(uint(stage) + 1);
    }

    function _nextStage() private  {
        stage = Stages(uint(stage) + 1);
    }

    /*
    ___________INITIALIZATION AND UPGRADE________________
    */


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
        address erc20Address = address(vaultToken); 
        //Add asset to the list of all assets.
        addErc20Asset(erc20Address);
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

    /* _________GETTERS_________ */

    function getERC20TokenAddress() public view returns(address){
        return address(vaultToken);
    }

    function getERC20TokenName() public view returns(string memory) {
        return vaultToken.name();
    }

    function getERC20TokenTicker() public view returns(string memory) {
        return vaultToken.symbol();
    }
    
    function getUserDeposit(address _user) public view returns(uint) {
        return userToEth[_user];
    }

    function getTotal() external view returns(uint) {
        return total;
    }

    function getUsersNum() external view returns(uint) {
        return users.length;
    }

    function getStake(address _user) public view atStage(Stages.FULL) returns (uint){
        return stakes[_user];
    }

    function getTokenAddress() public view atStage(Stages.ONSALE) returns (address){
        return tokenStorage.tokenAddr;
    }

    function getErc20Assets() public view atStage(Stages.FULL) returns(address[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this vault.
        */
        return vault.erc20;
    }


    /* ___________CONTROL TOKENS OPERATIONS_______________
    */
    
    function autoStake(uint _amount, address _user) public atStage(Stages.FULL) {
        //vaultToken.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_user] += _amount;
    }

    function claimTokens(uint _amount, address _user) public atStage(Stages.FULL) {  // 50
        require(msg.sender == _user);
        uint userStake = stakes[_user];  // 2
        if (userStake < _amount) {
            stakes[_user] -= userStake; // 2*50 < 50
            vaultToken.transfer(_user, userStake);
        } else {
            stakes[_user] -= _amount;
            vaultToken.transfer(_user, _amount);
            }
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

    function addErc20Asset(address _assetAddress) public onlyOwner {  
        require(vault.assetLocked[_assetAddress] == false, "This asset is already locked");
        vault.erc20.push(_assetAddress);
        vault.assetLocked[_assetAddress] = true;
    }
    

    function withdrawFinal() public atStage(Stages.SOLD) {
        require(userToEth[msg.sender] > 0, "This user is not a participant.");
        uint factor = total / userToEth[msg.sender];
        uint amount = tokenStorage.balanceAfter / factor;
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
    function recieveTokenPayment() public payable atStage(Stages.ONSALE) onlyInitiator transitionAfter {
        // Get the payment after successful NFT sale.
        tokenStorage.balanceAfter = address(this).balance+msg.value;
    }

    function tokenToInitiator() public atStage(Stages.ONSALE) onlyInitiator {
        if (tokenStorage.tokenType == 1) {
            IERC721 nftContract = IERC721(tokenStorage.tokenAddr);
            nftContract.safeTransferFrom(address(this), initiator, tokenStorage.tokenId);
        } else {
            IERC1155 nftContract = IERC1155(tokenStorage.tokenAddr);
            bytes memory data;
            nftContract.safeTransferFrom(address(this), initiator, tokenStorage.tokenId, 1, data);
    }
}

    /* 
    ___________NFT HOLDERS_______________
    */

    function onERC721Received(address operator, /*operator*/
                            address from, /*from*/
                            uint256 tokenId,
                            bytes calldata data
                            ) external atStage(Stages.FULL) transitionAfter override returns (bytes4) {
        tokenStorage.tokenAddr = msg.sender;
        tokenStorage.seller = from;
        tokenStorage.tokenId = tokenId;
        tokenStorage.tokenType = 1;
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator,
                              address from,
                              uint256 tokenId,
                              uint256 value,
                              bytes calldata data
                              ) external atStage(Stages.FULL) transitionAfter override returns (bytes4) {
        tokenStorage.tokenAddr = msg.sender;
        tokenStorage.seller = from;
        tokenStorage.tokenId = tokenId;
        tokenStorage.tokenType = 2;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator,
                                address from,
                                uint256[] calldata ids,
                                uint256[] calldata values,
                                bytes calldata data) external override returns(bytes4){
        return this.onERC1155BatchReceived.selector;
        }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}