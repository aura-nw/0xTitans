// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

contract KamatoTeam is ICar {
    uint256 bananasAhead;

    uint256 internal constant BANANA_MAX = 200;

    uint256 ACCEL_MAX = 50;
    uint256 ACCEL_MUL_MAX = 120;
    uint256 ACCEL_MUL_LATE_MAX = 400;
    uint256 SUPER_SHELL_MAX = 200;
    uint256 SHELL_MAX = 100;
    uint256 SHELL_LAST_100_MAX = 400;
    uint256 SHIELD_MAX = 80;

    // uint256 shields = 0;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external override {
        calculateBananas(bananas, allCars, ourCarIndex);
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        uint256 speed = ourCar.speed;
        uint256 remainingBalance = ourCar.balance;

        Monaco.CarData memory leadCar = allCars[0];

        uint256 rangeToWin = 1000 - (ourCar.y + ourCar.speed);
        // Win if possible.
        if (
            ourCar.y > 850
        ) {
            if(ourCar.balance >= monaco.getAccelerateCost(rangeToWin)){
                monaco.buyAcceleration(rangeToWin);
                return;
            }
            
        }

        buyFreeStuff(monaco);

        // Nếu xe hạng 1 chưa qua mức 200, thì cứ mỗi turn sẽ mua 1 tăng tốc
        if(leadCar.y <= 200){
            // return;
            if (monaco.getAccelerateCost(2) <= ACCEL_MUL_MAX){
                ourCar.balance -= uint24(monaco.buyAcceleration(2));
            }
        }
        else if (leadCar.y <= 500 ){
            // Chúng ta không phải lead
             if (monaco.getAccelerateCost(2) <= ACCEL_MAX){
                ourCar.balance -= uint24(monaco.buyAcceleration(2));
            }

            midGame(monaco, ourCarIndex, allCars);

        }
        else if (leadCar.y <= 700 ){
            if (monaco.getAccelerateCost(3) <= ACCEL_MAX){
                ourCar.balance -= uint24(monaco.buyAcceleration(3));
            }
            else {
                ourCar.balance -= uint24(monaco.buyAcceleration(2));
            }

            midGame(monaco, ourCarIndex, allCars);
        }
        else if (leadCar.y <= 850 ){
                
            if (monaco.getAccelerateCost(5) <= ACCEL_MUL_LATE_MAX){
                ourCar.balance -= uint24(monaco.buyAcceleration(5));
            }
            else if (monaco.getAccelerateCost(3) <= ACCEL_MUL_MAX){
                ourCar.balance -= uint24(monaco.buyAcceleration(3));
            }
            else {
                ourCar.balance -= uint24(monaco.buyAcceleration(1));
            }
            midGame(monaco, ourCarIndex, allCars);
        }
        else {

            if (ourCar.balance >= monaco.getAccelerateCost(3)){
                ourCar.balance -= uint24(monaco.buyAcceleration(3));
            }
            else {
                ourCar.balance -= uint24(monaco.buyAcceleration(1));
            }
            lateGame(monaco, ourCarIndex, allCars);
        }


        
       
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function sayMyName() external pure returns (string memory) {
        return "KhoaCar";
    }


    /** 
        Mua Chuối hoặc mua Khiên
     */
    function buyBananaOrShield(Monaco monaco, uint256 previousDistance) private {
        if(monaco.getShieldCost(1) < monaco.getBananaCost()){
             if (monaco.getShieldCost(1) <= SHIELD_MAX){
                monaco.buyShield(1);
            }
        }
        else {
            if (monaco.getBananaCost() <= BANANA_MAX){
                if(previousDistance <= 100){
                      monaco.buyBanana();
                }
              
            }
        }
    }
    

    

    function midGame(Monaco monaco,uint256 ourCarIndex, Monaco.CarData[] calldata allCars)private{
         // Xe ta là xe cuối
        if( ourCarIndex + 1 == allCars.length){
            if(monaco.getSuperShellCost(1) <= SUPER_SHELL_MAX){
                monaco.buySuperShell(1);
            }
            else if (monaco.getShellCost(1) <= SHELL_MAX){
                monaco.buyShell(1);
            }
        }
        // Xe ở giữa
        else if ( ourCarIndex != 0 ){
            if (monaco.getShellCost(1) <= SHELL_MAX){
                monaco.buyShell(1);
            }
            uint256 distance = allCars[ourCarIndex].y - allCars[2].y;
            buyBananaOrShield(monaco, distance);
                
        }
        // Đang lead
        else {
            if (monaco.getBananaCost() <= BANANA_MAX){
                monaco.buyBanana();
            }
        }
    }
    

    function lateGame(Monaco monaco,uint256 ourCarIndex, Monaco.CarData[] calldata allCars)private{
         // Xe ta là xe cuối
        if( ourCarIndex + 1 == allCars.length){
            if(monaco.getSuperShellCost(1) <= SUPER_SHELL_MAX){
                monaco.buySuperShell(1);
            }
            else if (monaco.getShellCost(1) <= SHELL_LAST_100_MAX){
                monaco.buyShell(1);
            }
        }
        // Xe ở giữa
        else if ( ourCarIndex != 0 ){
            if (monaco.getShellCost(1) <= SHELL_LAST_100_MAX){
                monaco.buyShell(1);
            }
            uint256 distance = allCars[ourCarIndex].y - allCars[2].y;
            buyBananaOrShield(monaco, distance);

            if(allCars[2].balance < 200){
                if (monaco.getAccelerateCost(3) <= ACCEL_MUL_LATE_MAX){
                    monaco.buyAcceleration(3);
                }
            }

            if(allCars[0].speed >= 3 && allCars[ourCarIndex].balance >= 5000 ){
                if(monaco.getSuperShellCost(1) <= SUPER_SHELL_MAX){
                    monaco.buySuperShell(1);
                }
                else if (monaco.getShellCost(1) <= SHELL_LAST_100_MAX){
                    monaco.buyShell(1);
                }
            }
            

        }
        // Đang lead
        else {
            if (monaco.getBananaCost() <= BANANA_MAX){
                monaco.buyBanana();
            }
        }
    }



     function buyFreeStuff(Monaco monaco) private {
        if (monaco.getAccelerateCost(1) == 0) {
            monaco.buyAcceleration(1);
        }
        if (monaco.getShieldCost(1) == 0) {
            monaco.buyShield(1);
        }
        if (monaco.getBananaCost() == 0) {
            monaco.buyBanana();
        }
        if (monaco.getSuperShellCost(1) == 0) {
            monaco.buySuperShell(1);
        }
        if (monaco.getShellCost(1) == 0) {
            monaco.buyShell(1);
        }
    }


    function calculateBananas(uint256[] calldata bananas,  Monaco.CarData[] calldata allCars, uint256 ourCarIndex)private {
        if(ourCarIndex == 0){
            bananasAhead = 0;
            return;
        }

        uint256 ourCarPosition = allCars[ourCarIndex].y;
        uint256 nextCarPosition = allCars[ourCarIndex-1].y;

        for (uint256 i = 0; i < bananas.length; i++) {
            if (bananas[i] > ourCarPosition) {
                ++bananasAhead;
            }
            if (bananas[i] > nextCarPosition) {
                break;
            }
        }
    }
}
