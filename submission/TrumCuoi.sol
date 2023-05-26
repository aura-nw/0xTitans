// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;



// The contract is based on version from Poligon team in last season
// With some local optimization 

import "./../../interfaces/ICar.sol";
/* import "forge-std/console.sol"; */

enum Status {
    EARLY_GAME,
    MID_GAME_1, 
    MID_GAME_2,
    LATE_GAME
}

contract TrumCuoi is ICar {
    uint256 internal constant BANANA_MAX = 400;
    uint256 ACCEL_MAX = 50;
    uint256 SUPER_SHELL_MAX = 300;
    uint256 SHELL_MAX = 150;
    uint256 SHIELD_MAX = 100;

    uint256 internal constant MID_GAME_1 = 250;
    uint256 internal constant MID_GAME_2 = 500;
    uint256 internal constant LATE_GAME = 900;

    uint256 internal constant PRICE_SHELL = 200;
    uint256 internal constant PRICE_ACC = 10;
    uint256 internal constant PRICE_SUPER_SHELL = 300;
    uint256 internal constant PRICE_BANANA = 200;
    uint256 internal constant PRICE_SHIELD = 200;

    uint256 internal constant FAST_VELOCITY = 10;


    Status status = Status.EARLY_GAME;
    uint256 bananasAhead;
    Monaco.CarData[] cars;
    uint256 aheadIndex;
    uint256 remainingBalance;
    uint256 speed = 0;
    bool bananaBought = false;
    bool superShellBought = false;
    uint256 shields = 0;

    uint256 ourCarIdx;

    modifier setUp(
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) {
        {
            ourCarIdx = ourCarIndex;
            speed = allCars[ourCarIndex].speed;
            shields = allCars[ourCarIndex].shield;
            remainingBalance = allCars[ourCarIndex].balance;
            bananasAhead = 0;

            // setup cars in order
            (uint256 firstIndex, uint256 secondIndex) = (
                (ourCarIndex + 1) % 3,
                (ourCarIndex + 2) % 3
            );
            (
                Monaco.CarData memory firstCar,
                Monaco.CarData memory secondCar
            ) = allCars[firstIndex].y > allCars[secondIndex].y
                    ? (allCars[firstIndex], allCars[secondIndex])
                    : (allCars[secondIndex], allCars[firstIndex]);
            cars.push(secondCar);
            cars.push(firstCar);

            uint256 maxY = allCars[ourCarIndex].y > firstCar.y
                ? allCars[ourCarIndex].y
                : firstCar.y;
            if (maxY > LATE_GAME) {
                ACCEL_MAX = 1000;
                SUPER_SHELL_MAX = 1200;
                SHELL_MAX = 900;
                SHIELD_MAX = 600;
                status = Status.LATE_GAME;
            } else if (maxY > MID_GAME_2) {
                status = Status.MID_GAME_2;
                /* status = Status.EARLY_GAME; */
            } else if (maxY > MID_GAME_1) {
                status = Status.MID_GAME_1;
                /* status = Status.EARLY_GAME; */
            } else {
                status = Status.EARLY_GAME;
            }

            // get all bananas in our way
            if (ourCarIndex != 0) {
                // we are not in first place
                if (ourCarIndex == 1) {
                    aheadIndex = 1;
                }
                uint256 ourCarPosition = allCars[ourCarIndex].y;
                uint256 nextCarPosition = ourCarIndex == 1
                    ? firstCar.y
                    : secondCar.y;
                for (uint256 i = 0; i < bananas.length; i++) {
                    if (bananas[i] > ourCarPosition) {
                        ++bananasAhead;
                    }
                    if (bananas[i] > nextCarPosition) {
                        break;
                    }
                }
            } else {
                aheadIndex = 2;
            }
        }
        _;
        delete cars;
        aheadIndex = 0;
        remainingBalance = 0;
        speed = 0;
        shields = 0;
        bananaBought = false;
        superShellBought = false;
        ACCEL_MAX = 50;
        SUPER_SHELL_MAX = 300;
        SHELL_MAX = 150;
        SHIELD_MAX = 150;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external override setUp(allCars, bananas, ourCarIndex) {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];

        getBananasOutOfTheWay(monaco);

        // Win if possible.
        if (
            ourCar.y > LATE_GAME &&
            remainingBalance >=
            monaco.getAccelerateCost((1000 - (ourCar.y + speed)))
        ) {
            monaco.buyAcceleration((1000 - (ourCar.y + speed)));
            return;
        }

        // spend it all in the end
        /* if ((ourCar.y > 985 || cars[1].y > 985) && remainingBalance > 300) { */
        /*     buyAccelerationFor(monaco, remainingBalance / 2); */
        /* } else { */
        /*     buyAcceleration(monaco); */
        /* } */

        buyAcceleration(monaco);
        buyCheapStuff(monaco);

        if (status == Status.LATE_GAME) {
            lateGameStrat(monaco, ourCarIndex);
        }

        /* if (status == Status.MID_GAME_2) { */
        /*     buyAcceleration(monaco); */
        /* } */
        /* if (status == Status.MID_GAME_1) { */
        /*     buyAcceleration(monaco); */
        /* } */
        /* if (status == Status.EARLY_GAME) { */
        /*     buyAcceleration(monaco); */
        /* } */
        if (shields == 0 && status != Status.EARLY_GAME) 
            buyShield(monaco, 1);

        tryToBuySuperShell(monaco, ourCarIndex);

    }

    function tryToBuySuperShell(Monaco monaco, uint256 ourCarIndex) private {
        // we take leading, skip it 
         if (ourCarIndex == 0) {
            return;
        }

        if (ourCarIndex == 1 && cars[0].speed > FAST_VELOCITY ) {
            buySuperShell(monaco);
            return ;
        }

        if (ourCarIndex == 2 && (cars[0].speed > FAST_VELOCITY || cars[1].speed > FAST_VELOCITY)) {
            buySuperShell(monaco);
            return ;
        }
    }
    // Buy something which very cheap compare to normal price
    function buyCheapStuff(Monaco monaco) private {

        // buy acceleration as long as it is cheap
        while (monaco.getAccelerateCost(1) <= PRICE_ACC / 4) {
            monaco.buyAcceleration(1);
            speed += 1;
        }
        
        // buy shield as long as it is cheap
        while (monaco.getShieldCost(1) <= PRICE_SHIELD) {
            monaco.buyShield(1);
            shields += 1;
        }
        
        if (ourCarIdx != 2 &&  monaco.getBananaCost() <= PRICE_BANANA / 4)  {
            monaco.buyBanana();
            bananaBought = true;
        }

        // if shell or super shell is cheap, buy it. 
        // Even if we are at leading position,still buy it, so the other cars can't buy it at cheap price.

        if (monaco.getSuperShellCost(1) <= PRICE_SUPER_SHELL / 4) {
            monaco.buySuperShell(1);
            superShellBought = true;
        }

        if (monaco.getShellCost(1) <= PRICE_SHELL / 4) {
            monaco.buyShell(1);
            if (bananasAhead > 0) {
                --bananasAhead;
                return;
            }
            if (aheadIndex != 2) {
                if (cars[aheadIndex].shield > 0) {
                    --cars[aheadIndex].shield;
                    return;
                }
                cars[aheadIndex].speed = 1;
                return;
            }
        }
    }

    function buyAccelerationFor(Monaco monaco, uint256 target) private {
        uint256 price = 0;
        uint256 i = 0;
        while (price <= target) {
            ++i;
            price = monaco.getAccelerateCost(i);
            if (gasleft() < 1_000_000) break;
        }
        --i;
        if (i > 0) {
            remainingBalance -= monaco.buyAcceleration(i);
            speed += i;
        }
    }

    function buyAcceleration(Monaco monaco) private {
        uint256 targetPurchase;
        /* console.log("status: "); */
        /* console.log(status); */
        if (status == Status.EARLY_GAME) {
            targetPurchase = 60; // TODO: need to tune this 
        } else 
        if (status == Status.MID_GAME_1) {
            targetPurchase = 100; // TODO: need to tune this 

        } else if (status == Status.MID_GAME_2) {
            targetPurchase = 200; // TODO: need to tune this 

        } else {
            targetPurchase = 900;
        }
        if (remainingBalance < targetPurchase) {
            // out of money, try to spend last money for cheap stuff
            
            buyCheapStuff(monaco);
            return;
        }
        buyAccelerationFor(monaco, targetPurchase);
    }

    function getBananasOutOfTheWay(Monaco monaco) private {
        uint256 remainingBananas = bananasAhead;
        if (remainingBananas == 0) return;

        // TODO: Posible an optimization: leave a banana here if its position nearly current car position + speed
        // in the latest version, supersehll does not affect  to banana, so never buy super shell
        // possible another optimization: limit the shell buying to a value 

        /* uint256 shellCost = monaco.getShellCost(remainingBananas); */
        if (remainingBananas > 3) remainingBananas = 3; // limit 

        buyShell(monaco, remainingBananas);

        /* uint256 superShellCost = monaco.getSuperShellCost(1); */
        /* if (shellCost > superShellCost) { */
        /*     // buy super shell */
        /*     buySuperShell(monaco); */
        /* } else { */
            // buy shells
        /* buyShell(monaco, remainingBananas); */
        /* } */
    }

    function lateGameStrat(Monaco monaco, uint256 ourCarIndex) private {
        Monaco.CarData storage first = cars[1];
        Monaco.CarData storage second = cars[0];

        uint256 maxSpeed = first.speed > second.speed
            ? first.speed
            : second.speed;

        // Handle cases where speed is too low and we are in last
        if (maxSpeed >= speed && aheadIndex == 0) {
            if (!buyAcceleration(monaco, maxSpeed + 1 - speed)) {
                buyAcceleration(monaco, 3);
            }
        }

        if (ourCarIndex != 0) {
            // handle cases when we are second or last
            uint256 shellCost = monaco.getShellCost(1);
            uint256 superShellCost = monaco.getSuperShellCost(1);

            if (first.y >= 990) {
                SHELL_MAX = remainingBalance / 2;
                SUPER_SHELL_MAX = remainingBalance / 2;
            }

            if (
                first.shield != 0 ||
                shellCost >= superShellCost ||
                ourCarIndex == 2
            ) {
                buySuperShell(monaco);
            } else {
                buyShell(monaco, 1);
            }
        }
    }

    function buyAcceleration(
        Monaco monaco,
        uint256 amount
    ) private returns (bool) {
        uint256 cost = monaco.getAccelerateCost(amount);
        // don't buy if price exceeds maximum
        if (cost > (ACCEL_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyAcceleration(amount);
            speed += amount;
            return true;
        }
        return false;
    }

    function buyShield(Monaco monaco, uint256 amount) private returns (bool) {
        if (shields >= 5) return false;
        uint cost = monaco.getShieldCost(amount);
        if (cost > (SHIELD_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyShield(amount);
            shields += amount;
            return true;
        }
        return false;
    }

    function buyBanana(Monaco monaco) private returns (bool) {
        if (aheadIndex == 0 || bananaBought) return false;
        uint cost = monaco.getBananaCost();
        if (cost > BANANA_MAX) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyBanana();
            bananaBought = true;
            return true;
        }
        return false;
    }

    function buyShell(Monaco monaco, uint256 amount) private returns (bool) {
        if (aheadIndex == 2) return false;
        uint remainingBanananas = bananasAhead;
        uint carAheadSpeed = cars[aheadIndex].speed;
        uint remainingShields = cars[aheadIndex].shield;
        if (
            // dont waste shell if car ahead is slow and there are no bananas
            carAheadSpeed <= 3 &&
            remainingBanananas == 0 &&
            remainingShields == 0
        ) return false;
        uint cost = monaco.getShellCost(amount);
        if (cost > (SHELL_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyShell(amount);
            if (remainingBanananas > 0) {
                if (remainingBanananas >= amount) {
                    bananasAhead -= amount;
                    return true;
                } else {
                    amount -= remainingBanananas;
                    bananasAhead = 0;
                }
            }
            if (remainingShields > 0) {
                if (remainingShields >= amount) {
                    cars[aheadIndex].shield -= uint32(amount);
                    return true;
                } else {
                    amount -= remainingShields;
                    cars[aheadIndex].shield = 0;
                }
            }
            cars[aheadIndex].speed = 1;
            return true;
        }
        return false;
    }

    function buySuperShell(Monaco monaco) private returns (bool) {
        if (aheadIndex == 2 || superShellBought) return false;
        uint256 tmpSpeed = 1;
        for (uint i = aheadIndex; i < 2; i++) {
            if (cars[i].speed > tmpSpeed) tmpSpeed = cars[i].speed;
        }
        if (tmpSpeed == 1) return false;
        uint cost = monaco.getSuperShellCost(1);
        if (cost > SUPER_SHELL_MAX) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buySuperShell(1);
            superShellBought = true;
            bananasAhead = 0;
            for (uint i = aheadIndex; i < 2; i++) {
                cars[i].speed = 1;
            }
            return true;
        }
        return false;
    }

    function sayMyName() external pure returns (string memory) {
        return "Need for Gas";
    }
}
