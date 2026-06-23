// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract SmartContractWallet {
    // متغير في الذاكرة الدائمة
    uint256 public gasGuzzler;

    receive() external payable {
        // هذه العملية وحدها (SSTORE) تطلب أكثر من 20,000 غاز!
        // بما أن العقد أرسل 10,000 فقط، ستفشل العملية فوراً (Out of Gas)
        gasGuzzler = 1;
    }
}

contract EtherFiExploiter {
    function processRedemption(address receiver) external payable {
        // السطر المصاب من مشروع Ether.fi
        (bool success, ) = receiver.call{value: msg.value, gas: 10_000}("");
        require(success, "EtherFiRedemptionManager: Transfer failed");
    }
}

contract RedemptionGasDoSTest is Test {
    EtherFiExploiter public exploiter;
    SmartContractWallet public victim;

    function setUp() public {
        exploiter = new EtherFiExploiter();
        victim = new SmartContractWallet();
        
        // شحن عقد الاختبار بـ 1 إيثيريوم
        vm.deal(address(this), 1 ether);
    }

    function test_Report_RedemptionGasLimitDoS() public {
        console.log("Testing redemption to Smart Contract Wallet with 10k gas limit...");
        
        // نتوقع الفشل لأن المحفظة ستحاول استهلاك 20,000+ غاز
        vm.expectRevert("EtherFiRedemptionManager: Transfer failed");
        
        // إرسال الإيثيريوم
        exploiter.processRedemption{value: 1 ether}(address(victim));
        
        console.log("PoC Success: Transaction reverted due to Out of Gas!");
    }
}
