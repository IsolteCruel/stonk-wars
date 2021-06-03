import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

const numOfBuyers = 4;

(async () => {
    const stdlib = await loadStdlib();
    const startingBalance = stdlib.parseCurrency(100);

    const fmt = (x) => stdlib.formatCurrency(x, 4);
    const getBalance = async (who) => fmt(await stdlib.balanceOf(who));

    const accFunder = await stdlib.newTestAccount(startingBalance);
    const accContestantArray = await Promise.all(
        Array.from({ length: numOfBuyers }, () =>
            stdlib.newTestAccount(startingBalance)
        )
    );

    const ctcFunder = accFunder.deploy(backend);
    const ctcInfo = ctcFunder.getInfo();

    const funderParams = {
        amt: stdlib.parseCurrency(20),
        deadline: 3,
    };

    // const ctcIsolte = accIsolte.attach(backend, ctcFunder.getInfo());
    // const ctcRudeus = accRudeus.attach(backend, ctcFunder.getInfo());
    // const Common = {
    //     informBounty: (bountyAmt) => {
    //         console.log(`${Who} saw a bounty of ${bountyAmt}`);
    //     },
    //     // informLeaderboard: (leaderboard) => {
    //     //     console.log(`${Who} saw the leaderboard as ${leaderboard}`)
    //     // },
    // };

    const Funder = (Who) => ({
        // ...Common,
        getBounty: () => {
            return funderParams;
        },
        informBounty: (bountyAmt, deadline) => {
            console.log(`${Who} saw a bounty of ${bountyAmt} and deadline ${deadline}`);
        },
        informLeaderboard: (leaderboard) => {
            leaderboard.forEach((element,i) => {
                console.log(`${i}: ${element.accountAddress} ${element.returnValue} ${element.inputValue} ${element.timestamp}`);
            })
            
        }
        // bounty: (input) => {
        //     return input % 69;
        // },
    });

    // const Contestant = (Who, amt) => ({
    //     ...Common,
    //     submitValue: () => {
    //         return amt;
    //     },
    // });
    const Contestant = (i) => ({
        // Who: `Contestant ${i}`,
        // ...Common,
        submitValue: () => {
            // if (i == 0) {
            if (Math.random() < 0.5) {
                const value = Math.floor(Math.random() * 30);
                console.log(`Contestant ${i} submitted ${value}`);
                return ['Some', value];
            }
            else {
                console.log(`Contestant ${i} o no`)
                return ['None', null];
            }
            // return null;
        },
        informWinner: (winner) => {
            if (stdlib.addressEq(winner, accBuyer)) {
                console.log(`Contestant ${i} won!`);
            }
        },
        informBounty: (bountyAmt, deadline) => {
            console.log(`Contestant ${i} saw a bounty of ${bountyAmt} and deadline ${deadline}`);
        }
        // shouldSubmitValue: () => {
        //     return Math.random() < 0.1;
        // }
    })

    await Promise.all([
        backend.Funder(
            ctcFunder,
            Funder('GuputaSan'),
        ),
        accContestantArray.map((accContestant, i) => {
            const ctcContestant = accContestant.attach(backend, ctcInfo);
            // const Who = `Contestant #${i}`;
            return backend.Contestant(ctcContestant, Contestant(i));
        })
    ]);

    for (let i = 0; i < accContestantArray.length; i++) {
        const afterBalance = await getBalance(accContestantArray[i]);
        console.log(`Contestant ${i} went to ${afterBalance}.`);
    }

    // const afterIsolte = await getBalance(accIsolte);
    // const afterRudeus = await getBalance(accRudeus);

    // console.log(`Isolte went to ${afterIsolte}.`);
    // console.log(`Rudeus went to ${afterRudeus}.`);

})();