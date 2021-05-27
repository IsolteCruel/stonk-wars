import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

const numOfBuyers = 2;

(async () => {
    const stdlib = await loadStdlib();
    const startingBalance = stdlib.parseCurrency(100);

    const accFunder = await stdlib.newTestAccount(startingBalance);
    const accBuyerArray = await Promise.all(
        Array.from({ length: numOfBuyers }, () =>
            stdlib.newTestAccount(startingBalance)
        )
    );

    const ctcFunder = accFunder.deploy(backend);
    const ctcInfo = ctcFunder.getInfo();

    const funderParams = {
        amt: stdlib.parseCurrency(20),
        deadline: 8,
    };

    // const ctcIsolte = accIsolte.attach(backend, ctcFunder.getInfo());
    // const ctcRudeus = accRudeus.attach(backend, ctcFunder.getInfo());
    const Common = {
        informBounty: (bountyAmt) => {
            console.log(`${Who} saw a bounty of ${bountyAmt}`);
        },
        // informLeaderboard: (leaderboard) => {
        //     console.log(`${Who} saw the leaderboard as ${leaderboard}`)
        // },
    };

    const Funder = (Who) => ({
        ...Common,
        getBounty: () => {
            return funderParams;
        },
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

    await Promise.all([
        backend.Funder(
            ctcFunder,
            Funder('GuputaSan'),
        ),
        accBuyerArray.map((accBuyer, i) => {
            const ctcBuyer = accBuyer.attach(backend, ctcInfo);
            const Who = `Contestant #${i}`;
            return backend.Contestant(ctcBuyer, {
                ...Common,
                submitValue: () => {
                    if (Math.random() < 0.1) {
                        value = Math.floor(Math.random() * 30);
                        console.log(`${Who} submitted ${value}`);
                        return value;
                    }
                    return null;
                },
                informWinner: (winner) => {
                    if (stdlib.addressEq(winner, accBuyer)) {
                        console.log(`${Who} won!`);
                    }
                },
                // shouldSubmitValue: () => {
                //     return Math.random() < 0.1;
                // }
            });
        })
    ]);

    // const afterIsolte = await getBalance(accIsolte);
    // const afterRudeus = await getBalance(accRudeus);

    // console.log(`Isolte went to ${afterIsolte}.`);
    // console.log(`Rudeus went to ${afterRudeus}.`);

})();