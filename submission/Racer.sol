// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";


contract Racer is ICar {
    uint256 constant CHEAP_COST = 20;
    uint256 constant FINISH_DISTANCE = 1000;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external override {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        if (FINISH_DISTANCE - ourCar.y <= ourCar.speed) {
            if (!buySuperShellOrNot(monaco, ourCar, 1)) {
                buyShellOrNot(monaco, ourCar, maxShellCanBuy(monaco, ourCar.balance));
            }
            return;
        }

        uint256 accelToWin = (FINISH_DISTANCE - ourCar.y) - ourCar.speed;
        if (maxAccelCanBuy(monaco, ourCar.balance) >= accelToWin) {
            buyAccelOrNot(monaco, ourCar, accelToWin);
            buyAccelOrNot(monaco, ourCar, maxAccelCanBuy(monaco, ourCar.balance));
            return;
        }

        (uint256 minTurn, uint256 otherCarIdx) = findCarHasMinTurn(monaco, allCars, ourCarIndex);

        if (minTurn < 1) {
            attack(monaco, allCars, ourCar, ourCarIndex, otherCarIdx, 17500);
        } else if (minTurn < 2) {
            attack(monaco, allCars, ourCar, ourCarIndex, otherCarIdx, 10000);
        } else if (minTurn < 3) {
            attack(monaco, allCars, ourCar, ourCarIndex, otherCarIdx, 5000);
        }

        uint256 maxAccelCost = minTurn == 0 ? 100000 : minTurn < 3 ? 5000 / minTurn : (3000 / minTurn);
        uint256 turnsToWin = ourCar.speed == 0 ? FINISH_DISTANCE : (FINISH_DISTANCE - ourCar.y) / ourCar.speed;
        raceSpeed(monaco, ourCar, turnsToWin, maxAccelCost);

        if (minTurn > 0) {
            uint256 maxCost = minTurn > 10 ? 20 : 500 / minTurn;
            uint256 superCost = monaco.getSuperShellCost(1);
            uint256 shellCost = monaco.getShellCost(2);
            if (superCost < maxCost && superCost < shellCost) {
                buySuperShellOrNot(monaco, ourCar, 1);
            } else if (shellCost < maxCost && shellCost < superCost) {
                buyShellOrNot(monaco, ourCar, 2);

            }
        }

        if (monaco.getShellCost(1) < CHEAP_COST) {
            buyShellOrNot(monaco, ourCar, 1);
        }
        if (monaco.getSuperShellCost(1) < CHEAP_COST) {
            buySuperShellOrNot(monaco, ourCar, 1);
        }
        if (monaco.getShieldCost(1) < CHEAP_COST) {
            buyShieldOrNot(monaco, ourCar, 1);
        }
        if (monaco.getBananaCost() < CHEAP_COST) {
            buyBananaOrNot(monaco, ourCar);
        }
    }

    function raceSpeed(Monaco monaco, Monaco.CarData memory ourCar, uint256 turnsToWin, uint256 maxAccelCost) internal {
        uint256 maxAccel = maxAccelCanBuy(monaco, maxAccelCost > ourCar.balance ? ourCar.balance : maxAccelCost);
        if (maxAccel == 0) {
            return;
        }

        uint256 bestTurnsToWin = (FINISH_DISTANCE - ourCar.y) / (ourCar.speed + maxAccel);

        if (bestTurnsToWin == turnsToWin) {
            return;
        }

        uint256 leastAccel = maxAccel;
        uint256 newTurnsToWin = 0;
        for (uint256 accel = maxAccel; accel > 0; accel--) {
            uint256 newTurnsToWin = (FINISH_DISTANCE - ourCar.y) / (ourCar.speed + accel);
            if (newTurnsToWin > bestTurnsToWin) {
                leastAccel = accel + 1;
                break;
            }
        }
        buyAccelOrNot(monaco, ourCar, leastAccel);
    }


    function findCarHasMinTurn(Monaco monaco, Monaco.CarData[] calldata allCars, uint256 ourCarIndex) internal returns (uint256 minTurn, uint256 otherCarIdx) {
        minTurn = 1000;
        for (uint256 i = 0; i < allCars.length; i++) {
            if (i != ourCarIndex) {
                Monaco.CarData memory car = allCars[i];
                uint256 maxSpeed = car.speed + maxAccelCanBuy(monaco, car.balance);
                uint256 turns = maxSpeed == 0 ? 1000 : (1000 - car.y) / maxSpeed;
                if (turns < minTurn) {
                    minTurn = turns;
                    otherCarIdx = i;
                }
            }
        }
    }

    function maxAccelCanBuy(Monaco monaco, uint256 balance) internal view returns (uint256 amount) {
        uint256 current = 25;
        uint256 min = 0;
        uint256 max = 50;
        while (max - min > 1) {
            uint256 cost = monaco.getAccelerateCost(current);
            if (cost > balance) {
                max = current;
            } else if (cost < balance) {
                min = current;
            } else {
                return current;
            }
            current = (max + min) / 2;
        }
        return min;

    }

    function maxShellCanBuy(Monaco monaco, uint256 balance) internal view returns (uint256 amount) {
        uint256 best = 0;
        for (uint256 i = 1; i < FINISH_DISTANCE; i++) {
            if (monaco.getShellCost(i) > balance) {
                return best;
            }
            best = i;
        }
    }

    function attack(Monaco monaco, Monaco.CarData[] calldata allCars, Monaco.CarData memory ourCar, uint256 ourCarIdx, uint256 otherCarIdx, uint256 maxCost) internal {
        if (otherCarIdx < ourCarIdx) {
            if (allCars[otherCarIdx].speed == 1) {
                return;
            }
            if (!buySuperShellOrNot(monaco, ourCar, 1)) {
                buyShellOrNot(monaco, ourCar, 1);
            }
        } else if (monaco.getBananaCost() < maxCost) {
            buyBananaOrNot(monaco, ourCar);
        } else {
            return;
        }
    }

    function buyAccelOrNot(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getAccelerateCost(amount)) {
            ourCar.balance -= uint32(monaco.buyAcceleration(amount));
            return true;
        }
        return false;
    }

    function buyShellOrNot(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getShellCost(amount)) {
            ourCar.balance -= uint32(monaco.buyShell(amount));
            return true;
        }
        return false;
    }

    function buySuperShellOrNot(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getSuperShellCost(amount)) {
            ourCar.balance -= uint32(monaco.buySuperShell(amount));
            return true;
        }
        return false;
    }

    function buyShieldOrNot(Monaco monaco, Monaco.CarData memory ourCar, uint256 amount) internal returns (bool success) {
        if (ourCar.balance > monaco.getShieldCost(amount)) {
            ourCar.balance -= uint32(monaco.buyShield(amount));
            return true;
        }
        return false;
    }

    function buyBananaOrNot(Monaco monaco, Monaco.CarData memory ourCar) internal returns (bool success) {
        if (ourCar.balance > monaco.getBananaCost()) {
            ourCar.balance -= uint32(monaco.buyBanana());
            return true;
        }
        return false;
    }

    function sayMyName() external pure returns (string memory) {
        return "Racer";
    }
}
