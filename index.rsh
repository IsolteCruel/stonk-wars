'reach 0.1';

const UserEntryType = Object({
    // address: Uint,
    returnedValue: UInt,
    timestamp: UInt
});

const CommonInterface =
{
    informBounty: Fun([UInt], Null),
    //TODO: check how to send leaderboard, perhaps maintain top X in an array
    //TODO: looks like map doesn't work kek
    // informLeaderboard: Fun([Map(Object({
    //     // address: Uint,
    //     returnedValue: UInt,
    //     timestamp: UInt
    // }))], Null)
}

const FunderInterface =
{
    ...CommonInterface,
    getBounty: Fun([], Object({
        deadline: UInt,
        amt: UInt,
    })),
    // bounty: Fun([UInt], UInt)
}

const ContestantInterface =
{
    ...CommonInterface,
    //TODO: what if code dies due to no int being returned here?
    submitValue: Fun([], Maybe(UInt)),
    // shouldSubmitValue: Fun([], Bool),
    informWinner: Fun([Address], Null)
}

export const main =
    Reach.App(
        {},
        [Participant('Funder', FunderInterface), ParticipantClass('Contestant', ContestantInterface)],
        (Funder, Contestant) => {

            const bountyFunction = (a) => (a % 69);

            Funder.only(() => {
                // const { amt, deadline } = declassify(interact.getBounty());
                const amt = 10;
                const deadline = 8;
                assume(amt > 0);
            });
            //TODO: the deadline expression of a timeout clause can be any equation over consensus state. https://docs.reach.sh/guide-timeout.html 
            Funder.publish(amt, deadline)
                .pay(amt);
            // commit();

            each([Contestant], () => {
                interact.informBounty(amt);
            });

            const initLeaderboard = new Map(UserEntryType);
            // commit();

            const [keepGoing, currentWinner] =
                //TODO: timestamp is currently ignored kek
                parallelReduce([true, { account: Funder, returnedValue: 0, timestamp: 0 }])
                    .invariant(true)
                    .while(keepGoing)
                    .case(
                        Contestant,
                        (() => ({
                            // value = declassify(interact.submitValue(ticketPrice));
                            // return {
                            //TODO: BIG HACKY MOVE: for some reason i can't seem to "return" an object with some logic without errors 
                            when: declassify(isSome(interact.submitValue())),
                            msg: declassify(interact.submitValue())
                            // }
                            // if (isSome(value)) {
                            //     return {
                            //         when: true,
                            //         msg: value
                            //     }
                            // }
                            // else {
                            //     return {
                            //         when: false
                            //     }
                            // }
                        })),
                        // ((_) => 0),
                        ((msg) => {
                            const currentContestant = this;
                            // const value 
                            const evaluatedValue = bountyFunction(fromSome(msg, 0));
                            // previousEntry = leaderboard[currentContestant];
                            // if (isSome(previousEntry)) {
                            //     if (evaluatedValue > previousEntry.returnedValue) {
                            const newEntry = {
                                returnedValue: evaluatedValue,
                                timestamp: 0
                            };
                            // leaderboard[currentContestant] = newEntry;
                            const newWinner = evaluatedValue > currentWinner.returnedValue ?
                                {
                                    ...newEntry,
                                    account: currentContestant
                                } :
                                currentWinner;

                            //     }
                            // }
                            return [true, newWinner];
                        }))
                    .timeout(deadline, () => {
                        Anybody.publish();
                        return [false, currentWinner];
                    });


            // commit();

            transfer(amt).to(currentWinner.account);
            commit();

            exit();
        }
    );