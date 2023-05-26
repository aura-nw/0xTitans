// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract Vinfast is ICar {
    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external override {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        bool hasBuyBanana = false;
        uint256 maxSpeed;
        uint256 maxShellCost;
        uint256 maxSuperShellCost;
        uint256 maxShieldCost;
          if (ourCar.y > 0) {
            maxSpeed = 8;
            maxShellCost = 80;
            maxShellCost = 80;
            maxShieldCost = 80;
          }
          if (ourCar.y > 400) {
            maxSpeed = 14;
            maxShellCost = 100;
            maxSuperShellCost = 140;
            maxShieldCost = 120;
          }
          if (ourCar.y > 700) {
            maxSpeed = 20;
            maxShellCost = 200;
            maxSuperShellCost = 250;
            maxShieldCost = 400;
          }
        if (
          ourCar.y > 850 &&
            ourCar.balance >=
            monaco.getAccelerateCost(1000 - (ourCar.y + ourCar.speed))
        ) {
            monaco.buyAcceleration(1000 - (ourCar.y + ourCar.speed));
            return;
        }

        
        

if (ourCar.balance > monaco.getBananaCost() && monaco.getBananaCost() < 80) {
  if (!hasBuyBanana) {
                    ourCar.balance -= uint24(monaco.buyBanana());
                    hasBuyBanana = true;
                  }
}
if (ourCar.balance > monaco.getShellCost(1) && monaco.getShellCost(1) < maxShellCost) {
                    ourCar.balance -= uint24(monaco.buyShell(1));
}
if (ourCar.balance > monaco.getSuperShellCost(1) && monaco.getSuperShellCost(1) < maxSuperShellCost) {
                    ourCar.balance -= uint24(monaco.buySuperShell(1));
}
if (ourCar.balance > monaco.getShieldCost(1) && monaco.getShieldCost(1) < maxShieldCost) {
                    ourCar.balance -= uint24(monaco.buyShield(1));
}
        // If we can afford to accelerate 3 times, let's do it.
        if (ourCar.y < 10) {
          uint32 targetSpeed = 1;
          while(monaco.getAccelerateCost(targetSpeed) < 800) {
            targetSpeed++;
          }
          ourCar.balance -= uint24(monaco.buyAcceleration(targetSpeed));
          ourCar.speed += targetSpeed;
          return;
        } else {
          
          if (ourCar.speed < maxSpeed) {

          uint32 targetSpeed = 1;
          while(monaco.getAccelerateCost(targetSpeed) <= 200 && ourCar.balance > monaco.getAccelerateCost(targetSpeed)) {
            targetSpeed++;
          }
          ourCar.balance -= uint24(monaco.buyAcceleration(targetSpeed));
          ourCar.speed += targetSpeed;
          }
        }
        
        if (ourCarIndex == 0) {
          if (ourCar.y - allCars[1].y > 2*allCars[1].speed || ourCar.y < 400) {
hasBuyBanana = true;
          }
          if (allCars[1].balance > monaco.getShellCost(1) || allCars[1].balance > monaco.getSuperShellCost(1)) {
            uint256 bananaCost = monaco.getBananaCost()*2;
            uint256 shieldCost = monaco.getShieldCost(2);
            for (uint256 i = 0; i < bananas.length; i++) {
            if (bananas[i] > allCars[1].y) {
                 hasBuyBanana = true;
            }
        }
            bool useBanana =hasBuyBanana ?false : shieldCost > bananaCost;
            if (ourCar.balance >= min(bananaCost, shieldCost) && min(bananaCost, shieldCost) <= 1800*uint256(ourCar.y/1000)) {
                if (useBanana) {
                  
                  if (!hasBuyBanana) {
                    ourCar.balance -= uint24(monaco.buyBanana());
                    hasBuyBanana = true;
                  }
                } else {
                  if (ourCar.shield == 0) ourCar.balance -= uint24(monaco.buyShield(2));
                  if (ourCar.shield == 1) ourCar.balance -= uint24(monaco.buyShield(1));
                }
            }
          } else {
            if (allCars[1].speed > ourCar.speed && allCars[1].y > 700) {
              if (monaco.getBananaCost() <  monaco.getAccelerateCost(allCars[1].speed - ourCar.speed + 1) && monaco.getBananaCost() < ourCar.balance) {
                if (monaco.getBananaCost() < 300 && !hasBuyBanana) {
                ourCar.balance -= uint24(monaco.buyBanana());
                }
              } 
            }
          }
        }

        if (ourCarIndex == 1||ourCarIndex == 2) {
          if (bananas.length > 0) {
            for (uint256 i = 0; i < bananas.length; i++) {
            if (bananas[i] > ourCar.y) {
                if (monaco.getShellCost(1) < monaco.getAccelerateCost(uint256 (ourCar.speed / 2))) {
                  if ( monaco.getShellCost(1) < 1000 &&  monaco.getShellCost(1) < ourCar.balance) {
            ourCar.balance -= uint24(monaco.buyShell(1));
          }
                } else {
                  if (  monaco.getAccelerateCost(uint256 (ourCar.speed / 2)) < 1000 &&   monaco.getAccelerateCost(uint256 (ourCar.speed / 2)) < ourCar.balance) {
            ourCar.balance -= uint24( monaco.getAccelerateCost(uint256 (ourCar.speed / 2)));
          }
                }
            }
        }
          }
         if(allCars[0].shield > 0) {
          if ( monaco.getShellCost(1) < 1000 &&  monaco.getShellCost(1) < ourCar.balance) {
            ourCar.balance -= uint24(monaco.buyShell(1));
          }
         } else {
          if ( monaco.getShellCost(1) < 2000 &&  monaco.getShellCost(1) < ourCar.balance) {
            ourCar.balance -= uint24(monaco.buyShell(1));
          }
         }
        }

        
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function sayMyName() external pure returns (string memory) {
        return "ExampleCar";
    }
}
