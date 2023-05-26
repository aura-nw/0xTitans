// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract Daijoubu is ICar {
    uint256 constant FLOOR = 30;
    uint16 internal last_turn = 0;
    uint16 internal current_turn = 0;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external {
        current_turn += 1;

        Monaco.CarData memory ourCar = allCars[ourCarIndex];

        uint256 turnsToWin = ourCar.speed == 0 ? 1000 : (1000 - ourCar.y) / ourCar.speed;

        // were about to win this turn, no need to accelerate
        // just shell everyone
        if (turnsToWin == 0) {
            if (!superShell(monaco, ourCar, 1)) {
                shell(monaco, ourCar, maxShell(monaco, ourCar.balance));
            }
            return;
        }

        // Win if possible.
        if (
            ourCar.y > 850 &&
            ourCar.balance >=
            monaco.getAccelerateCost(1000 - (ourCar.y + ourCar.speed))
        ) {
            monaco.buyAcceleration(1000 - (ourCar.y + ourCar.speed));
            return;
        }

        // so cheap, why not
        if (monaco.getShellCost(1) < FLOOR) {
            monaco.buyShell(1);
        }
        if (monaco.getSuperShellCost(1) < FLOOR) {
            monaco.buySuperShell(1);
        }
        if (monaco.getShieldCost(1) < FLOOR) {
            monaco.buyShield(1);
        }
        if (monaco.getBananaCost() < FLOOR) {
            monaco.buyBanana();
        }


        if (
            ourCar.speed < 20 &&
            ourCar.balance >= monaco.getAccelerateCost(1)
        ) {
            if (ourCar.y < 200 && ourCar.y < 835 ) {
                for (uint x = 2; x > 0; x --) {
                    if ( ourCar.balance >= monaco.getAccelerateCost(x)) {
                        monaco.buyAcceleration(x);
                        break;
                    }
                }

                if (
                    ourCar.speed > 15 &&
                    ourCarIndex != 2 &&
                    ourCar.balance >= monaco.getShieldCost(1)
                ) {
                    monaco.buyShield(1);
                }

            }else {
                monaco.buyAcceleration(1);
            }
        }


        // Go for a final boost when it makes sense
        if (
            ourCar.y > 835 && ourCar.speed < 15
        ) {
            for (uint x = 5; x > 0; x --) {
                if ( ourCar.balance >= monaco.getAccelerateCost(x)) {
                    monaco.buyAcceleration(x);
                    if (ourCarIndex != 0) {
                        if (ourCar.balance >= monaco.getShellCost(2)) {
                            monaco.buyShell(2);
                        }
                    } 
                    if (ourCar.balance >= monaco.getShieldCost(1)) {
                        monaco.buyShield(1);
                    }
                 
                    break;
                }
            }
        }

        
        //Handle middle game, when our position is the first, then buy banana
        if ((ourCarIndex == 0 && (allCars[1].speed > 15 || allCars[2].speed > 15 )) || current_turn == 0 || (ourCarIndex == 1 && allCars[2].speed > 15)) {
            monaco.buyBanana();
        }

    }

    function superShell(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getSuperShellCost(amount)) {
            ourCar.balance -= uint32(monaco.buySuperShell(amount));
            return true;
        }
        return false;
    }

    function maxShell(Monaco monaco, uint256 balance) internal view returns (uint256 amount) {
        uint256 best = 0;
        for (uint256 i = 1; i < 1000; i++) {
            if (monaco.getShellCost(i) > balance) {
                return best;
            }
            best = i;
        }
    }

    function shell(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getShellCost(amount)) {
            ourCar.balance -= uint32(monaco.buyShell(amount));
            return true;
        }
        return false;
    }

    function sayMyName() external pure returns (string memory) {
        return "Daijoubu";
    }
}
