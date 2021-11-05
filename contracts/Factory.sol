// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";
import "./CRUD.sol";
import "./Token.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";


contract Factory is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    address public initiator;  // Offchain initiator
    uint vaultCount;
    CRUD vaults; 

    mapping(address => string) vaultToCeramic;
    modifier onlyInitiator {require(msg.sender == initiator); _;}

    event NewVault(string name, address indexed vault, address indexed tokenAddress);
    event NewDeposit(uint vaultId, address sender, uint deposit);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setInitiator(address _new_initiator) public onlyOwner {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }

    // ToDo is it safe to make initial function public?
    function initialize(address _initiator) public initializer {
        __Ownable_init_unchained();
        initiator = _initiator;
        vaults = new CRUD();
    }

    function newVault(string memory _vaultName, 
                    string memory _ticker, 
                    uint _shares_amount) public payable returns(address) {
        //  Building the brand new vault.
        Vault vault = new Vault();
        // Create Vault and the pool inside of it.
        vault.initialize(_vaultName, _ticker, _shares_amount);
        address vaultAddr = address(vault);
        address tokenAddress = vault.getTokenAddress();
         // Send eth to the pool.
        vault.recieveDeposit{value:msg.value}(msg.sender);
        console.log("Vault created at:", vaultAddr);
        // Add vault addres and vault ID to dynamic array.
        vaults.create(vaultCount, vaultAddr);
        emit NewVault(_vaultName, vaultAddr, tokenAddress);
        vaultCount++;
        //Return the address of the created Vault.
        return vaultAddr;
    }

    function delegateToCeramic(address _vaultAddress) public view returns(string memory) {
        return vaultToCeramic[_vaultAddress];
    }

    function getVaultAddress(uint _id) public view returns (address) {
        return vaults.read(_id);
    }

    function delVault(uint _id) public onlyInitiator {
        vaults.del(_id);
    }

    function getAllVaults() public view returns (CRUD.Instance[] memory){
        return vaults.readAll();
    }

    function setupVault(address _vaultAddr, address _initiator) public onlyOwner {
        Vault vault = Vault(_vaultAddr);
        vault.setInitiator(_initiator);
    }

    function distributeVaultTokens(address _vaultAddr) public onlyOwner {
        Vault vault = Vault(_vaultAddr);
        vault.distributeTokens();
    }

}