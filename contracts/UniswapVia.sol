pragma solidity ^0.5.0;

import "./SnowflakeVia.sol";
import "./interfaces/HydroInterface.sol";
import "./interfaces/SnowflakeInterface.sol";

contract UniswapFactory {
    function getExchange(address token) external view returns (address);
}

contract UniswapExchange {
    function tokenToTokenTransferInput(
        uint tokensSold,
        uint minTokensBought,
        uint minEthBought,
        uint deadline,
        address recipient,
        address tokenAddr
    ) external returns (uint);
}

contract UniswapVia is SnowflakeVia {
    address public uniswapHydroExchangeAddress;
    UniswapExchange private uniswapHydroExchange;

    constructor (address _snowflakeAddress, address uniswapFactoryAddress) SnowflakeVia(_snowflakeAddress) public {
        setUniswapHydroExchangeAddress(uniswapFactoryAddress);
    }

    function setUniswapHydroExchangeAddress(address uniswapFactoryAddress) public onlyOwner() {
        uniswapHydroExchangeAddress = UniswapFactory(uniswapFactoryAddress)
            .getExchange(SnowflakeInterface(snowflakeAddress).hydroTokenAddress());
        uniswapHydroExchange = UniswapExchange(uniswapHydroExchangeAddress);
    }

    // end recipient is an EIN
    function snowflakeCall(
        address /* resolver */,
        uint /* einFrom */,
        uint /* einTo */,
        uint /* amount */,
        bytes memory /* snowflakeCallBytes */
    ) public senderIsSnowflake() {
        revert("Not Implemented.");
    }

    // end recipient is an EIN, no from field
    function snowflakeCall(
        address /* resolver */,
        uint /* einTo */,
        uint /* amount */,
        bytes memory /* snowflakeCallBytes */
    ) public senderIsSnowflake() {
        revert("Not Implemented.");
    }

    // end recipient is an address
    function snowflakeCall(
        address /* resolver */, uint /* einFrom */, address payable to, uint amount, bytes memory snowflakeCallBytes
    ) public senderIsSnowflake() {
        convertFromHYDRO(to, amount, snowflakeCallBytes);
    }

    // end recipient is an address, no from field
    function snowflakeCall(
        address /* resolver */, address payable to, uint amount, bytes memory snowflakeCallBytes
    ) public senderIsSnowflake() {
        convertFromHYDRO(to, amount, snowflakeCallBytes);
    }

    function convertFromHYDRO(address payable to, uint amount, bytes memory snowflakeCallBytes)
        private returns (uint tokensBought)
    {
        (address tokenAddress, uint minTokensBought, uint minEthBought, uint deadline)= abi.decode(
            snowflakeCallBytes, (address, uint, uint, uint)
        );

        HydroInterface(SnowflakeInterface(snowflakeAddress).hydroTokenAddress()).approve(uniswapHydroExchangeAddress, amount);

        uint _tokensBought = uniswapHydroExchange.tokenToTokenTransferInput(
            amount, minTokensBought, minEthBought, deadline, to, tokenAddress
        );

        return _tokensBought;
    }
}
