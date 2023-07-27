// SPDX-License-Identifier: MIT

// Have our invariant aka properties hold true for all time

// What are our invariants?

// 1. The total supply of DSC should be less than the total value of collateral

// 2. Getter view functions should never revert <- evergreen invariant

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address btc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, btc,) = config.activeNetworkConfig();
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
        //targetContract(address(dsce));
    }

    function invariant_protocolMusthaveMoreValueThanTotalSupply() public view {
        // get the value of all the collateral in the protocol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = IERC20(btc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(btc, totalBtcDeposited);

        console.log("wethValue:", wethValue);
        console.log("wbtcValue:", wbtcValue);
        console.log("totalSupply:", totalSupply);
        console.log("Times mint called", handler.timesMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view{
        dsce.getLiquidationBonus();
        dsce.getPrecision();
    }
}