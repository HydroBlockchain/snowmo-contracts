pragma solidity ^0.5.0;

import "./interfaces/HydroInterface.sol";
import "./interfaces/SnowflakeInterface.sol";
import "./interfaces/IdentityRegistryInterface.sol";

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/math/SafeMath.sol";

// @deprecated
/*
contract HydroRinkeby {
    function getMoreTokens() external;
}
*/

contract DemoHelper is Ownable {
    using SafeMath for uint;
    
    address public snowflakeAddress;
    SnowflakeInterface private snowflake;
    IdentityRegistryInterface private identityRegistry;
    address public snowMoResolverAddress;
    
    address public hydroTokenAddress;
    uint internal _regUsers;
    
    uint constant atomicUnit = 10**18;
    
    uint constant milestoneUno = 2000;
    uint constant rewardUno = 10000 * atomicUnit;
    
    uint constant milestoneDuo = milestoneUno + 3000;
    uint constant rewardDuo = 5000 * atomicUnit;
    
    uint constant milestoneTrio = milestoneDuo + 5000;
    uint constant rewardTrio = 1000 * atomicUnit;
    
    constructor (address _snowflakeAddress, address _resolverAddress, address _hydroTokenAddress) public {
        snowflakeAddress = _snowflakeAddress;
        snowflake = SnowflakeInterface(snowflakeAddress);
        identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
        snowMoResolverAddress = _resolverAddress;
        
        hydroTokenAddress = _hydroTokenAddress;
    }

    // wrap createIdentityDelegated and initialize the client raindrop resolver
    function createIdentityDelegated(
        address associatedAddress, address tokensReceivedAddress,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) public returns (uint ein) {
        // create 1484 identity
        address[] memory _providers = new address[](2);
        _providers[0] = snowflakeAddress;
        _providers[1] = address(this);

        uint _ein = identityRegistry.createIdentityDelegated(
            associatedAddress, associatedAddress, _providers, new address[](0), v, r, s, timestamp
        );

        // add snowmo resolver
        snowflake.addResolverAsProvider(
            _ein, snowMoResolverAddress, true, 0, abi.encode(associatedAddress, tokensReceivedAddress)
        );

        // @deprecated
        // get free testnet tokens
        // HydroRinkeby(snowflake.hydroTokenAddress()).getMoreTokens();

        // deposit new tokens into snowflake
        // HydroInterface(snowflake.hydroTokenAddress())
        //     .approveAndCall(snowflakeAddress, 10000000000000000000000, abi.encode(_ein));
        
        // Increment users and Apply Reward Logic
        _regUsers.add(1);
        
        // Calculate reward
        uint rewards;
        if (_regUsers <= milestoneUno) {
            rewards = rewardUno;
        }
        else if (_regUsers <= milestoneDuo) {
            rewards = rewardDuo;
        }
        else if (_regUsers <= milestoneTrio) {
            rewards = rewardTrio;
        }
        
        // Give reward to snowflake id if reward greater than 0
        if (rewards > 0) {
            HydroInterface(snowflake.hydroTokenAddress())
                .approveAndCall(snowflakeAddress, rewards, abi.encode(_ein));
        }
        
        return _ein;
    }
    
    function getRegisteredUsers() public view returns (uint registeredUsers) {
        registeredUsers = _regUsers;
    }
    
    function sethydroTokenAddress(address _newhydroTokenAddress) public onlyOwner {
        hydroTokenAddress = _newhydroTokenAddress;
    }
    
    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
        
        return true;
    }
    
    function withdrawToken(uint amount) public onlyOwner returns (bool) {
        HydroInterface hydro = HydroInterface(hydroTokenAddress);
        hydro.transfer(msg.sender, amount);
        
        return true;
    }
    
    function() external payable { }
}
