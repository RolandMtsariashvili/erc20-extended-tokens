// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenWrapper} from "../src/TokenWrapper.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract RareSkillsToken is ERC20("RareSkills", "RS") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract RareSkillsToken2 is ERC20("RareSkills2", "RS2") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 
}

contract RareSkillsToken3 is ERC20("RareSkills3", "RS3") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract RareSkillsToken4 is ERC20("RareSkills4", "RS4") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 

    function name() public pure override returns (string memory) {
        return "RareSkills4";
    }

    function symbol() public pure override returns (string memory) {
        require(false, "fail");
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract RareSkillsToken5 is ERC20("RareSkills5", "RS5") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 
    
    function name() public pure override returns (string memory) {
        revert();
    }

    function symbol() public pure override returns (string memory) {
        return "RS5";
    }
}

contract RareSkillsToken6 is ERC20("RareSkills6", "RS6") {
    constructor() {
        _mint(msg.sender, 1e18);
    } 
    
    function decimals() public pure override returns (uint8) {
        revert();
    }
}


contract TokenWrapMetadataTest is Test {

    function test_Instantiation1() public {
        ERC20 token = new RareSkillsToken();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped RareSkills");
        assertEq(wrap.symbol(), "wRS");
        assertEq(wrap.decimals(), 18);
    }

    function test_Instantiation2() public {
        ERC20 token = new RareSkillsToken2();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped RareSkills2");
        assertEq(wrap.symbol(), "wRS2");
        assertEq(wrap.decimals(), 18);
    }

    function test_Instantiation3() public {
        ERC20 token = new RareSkillsToken3();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped RareSkills3");
        assertEq(wrap.symbol(), "wRS3");
        assertEq(wrap.decimals(), 6);
    }

    function test_Instantiation4() public {
        ERC20 token = new RareSkillsToken4();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped RareSkills4");
        assertEq(wrap.symbol(), "w");
        assertEq(wrap.decimals(), 6);
    }

    function test_Instantiation5() public {
        ERC20 token = new RareSkillsToken5();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped");
        assertEq(wrap.symbol(), "wRS5");
        assertEq(wrap.decimals(), 18);
    }

    function test_Instantiation6() public {
        ERC20 token = new RareSkillsToken6();
        // expect the arguments to be ignored if the functions are not missing
        TokenWrapper wrap = new TokenWrapper(address(token));

        assertEq(wrap.name(), "Wrapped RareSkills6");
        assertEq(wrap.symbol(), "wRS6");
        assertEq(wrap.decimals(), 0);
    }

    function test_Wrap() public {
        ERC20 token = new RareSkillsToken();
        TokenWrapper wrap = new TokenWrapper(address(token));

        token.approve(address(wrap), 1e18);

        wrap.wrap(1e18);

        assertEq(wrap.balanceOf(address(this)), 1e18);
        assertEq(token.balanceOf(address(wrap)), 1e18);
    }

    function test_unwrap() public {
        ERC20 token = new RareSkillsToken();
        TokenWrapper wrap = new TokenWrapper(address(token));

        token.approve(address(wrap), 1e18);

        wrap.wrap(1e18);

        assertEq(wrap.balanceOf(address(this)), 1e18);
        assertEq(token.balanceOf(address(wrap)), 1e18);

        wrap.unwrap(1e18);

        assertEq(wrap.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(wrap)), 0);
        assertEq(token.balanceOf(address(this)), 1e18);
    }
}
